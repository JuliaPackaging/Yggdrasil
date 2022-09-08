const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr/"

const GIT_TAGS = Dict(
    v"4.2.0" => "18133451948a83055ca5ebfb5ba1bd536ed0bcb611df98829f1251a98a38f730",
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
)
const GIT_TAGS_CLR = Dict(
    v"4.2.0" => "c57525af32c59becf56fd83cdd61f5320a95024d9baa7fb729a01e7a9fcdfd78",
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const CLR_PATCHES = Dict(
    v"4.2.0" => raw"""
    # Link rt. OpenCL needs it, otherwise we get `undefined symbol: clock_gettime`.
    atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-link-lrt.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
    """,
    v"4.5.2" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
    """,
)

const CL_PATCHES = Dict(
    v"4.2.0" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-opencl.patch
    """,
    v"4.5.2" => "",
)

const CLR_CMAKE = Dict(
    v"4.2.0" => raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix}/rocclr \
        -DCMAKE_BUILD_TYPE=Release \
        -DOPENCL_DIR=${OPENCL_SRC} \
        ..
    make -j${nproc}
    make install
    """,
    v"4.5.2" => raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix}/rocclr \
        -DCMAKE_BUILD_TYPE=Release \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        ..
    make -j${nproc} # no install target
    """,
)

const CL_CMAKE = Dict(
    v"4.2.0" => raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix}/opencl \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_COMGR_LIBRARY=ON \
        -DBUILD_TESTS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        ..
    make -j${nproc}
    make install
    """,
    v"4.5.2" => raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix}/opencl \
        -DCMAKE_BUILD_TYPE=Release \
        -DROCM_PATH=${prefix} \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        -DROCCLR_INCLUDE_DIR=${ROCclr_DIR}/include \
        -DBUILD_TESTS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        ..
    make -j${nproc}
    make install
    """,
)

const NAME = "ROCmOpenCLRuntime"

function configure_build(version)
    buildscript = raw"""
    export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
    export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

    # Build ROCclr
    cd ${ROCclr_DIR}
    """ *
    CLR_PATCHES[version] *
    raw"""
    mkdir build && cd build
    """ *
    CLR_CMAKE[version] *
    raw"""
    # Build OpenCL.
    cd ${OPENCL_SRC}
    """ *
    CL_PATCHES[version] *
    raw"""
    mkdir build && cd build
    """ *
    CL_CMAKE[version] *
    raw"""
    install_license ${OPENCL_SRC}/LICENSE.txt
    """

    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
        ArchiveSource(
            ROCM_GIT_CLR * "archive/rocm-$(version).tar.gz", GIT_TAGS_CLR[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    products = Product[LibraryProduct(["libOpenCL"], :libOpenCL, "opencl/lib")]
    if version == v"4.2.0"
        push!(products, FileProduct(
            "rocclr/lib/libamdrocclr_static.a", :libamdrocclr_static))
    end

    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency("hsa_rocr_jll", version),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("ROCmCompilerSupport_jll", version),
        Dependency("Libglvnd_jll"),
        Dependency("Xorg_libX11_jll"),
        Dependency("Xorg_xorgproto_jll"),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, products, dependencies
end
