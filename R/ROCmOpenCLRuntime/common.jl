const NAME = "ROCmOpenCLRuntime"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr/"

const GIT_TAGS = Dict(
    v"4.2.0" => "18133451948a83055ca5ebfb5ba1bd536ed0bcb611df98829f1251a98a38f730",
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
    v"5.2.3" => "932ea3cd268410010c0830d977a30ef9c14b8c37617d3572a062b5d4595e2b94",
)
const GIT_TAGS_CLR = Dict(
    v"4.2.0" => "c57525af32c59becf56fd83cdd61f5320a95024d9baa7fb729a01e7a9fcdfd78",
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
    v"5.2.3" => "0493c414d4db1af8e1eb30a651d9512044644244488ebb13478c2138a7612998",
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
    v"5.2.3" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
    """,
)

const CL_PATCHES = Dict(
    v"4.2.0" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-opencl.patch
    """,
)

function get_clr_cmake(cmake_cxx_prefix::String, version::VersionNumber)
    clr_cmake = raw"""
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix}/rocclr \
        -DCMAKE_BUILD_TYPE=Release \
    """
    if version < v"4.5.2"
        clr_cmake *= raw"""
        -DOPENCL_DIR=${OPENCL_SRC} \
        """
    else
        clr_cmake *= raw"""
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        """
    end
    clr_cmake *= """
    ..
    """
    clr_cmake *= raw"""
    make -j${nproc}
    """
    if version < v"4.5.2"
        clr_cmake *= """
        make install
        """
    end
    cmake_cxx_prefix * clr_cmake
end

function get_opencl_cmake(cmake_cxx_prefix::String, version::VersionNumber)
    cl_cmake = raw"""
    cmake \
        -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${prefix}" \
        -DCMAKE_INSTALL_PREFIX=${prefix}/opencl \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DUSE_COMGR_LIBRARY=ON \
    """
    if version ≥ v"4.5.2"
        cl_cmake *= raw"""
        -DROCM_PATH=${prefix} \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        -DROCCLR_INCLUDE_DIR=${ROCclr_DIR}/include \
        """
    end
    cl_cmake *= """
    ..
    """
    cl_cmake *= raw"""
    make -j${nproc}
    make install
    """
    cmake_cxx_prefix * cl_cmake
end

function configure_build(version)
    cmake_cxx_prefix = raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang \
    CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    """
    clr_cmake = get_clr_cmake(cmake_cxx_prefix, version)
    opencl_cmake = get_opencl_cmake(cmake_cxx_prefix, version)

    buildscript = raw"""
    export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
    export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

    # Build ROCclr
    cd ${ROCclr_DIR}
    """ *
    get(CLR_PATCHES, version, "") *
    raw"""
    mkdir build && cd build
    """ *
    clr_cmake *
    raw"""
    # Build OpenCL.
    cd ${OPENCL_SRC}
    """ *
    get(CL_PATCHES, version, "") *
    raw"""
    mkdir build && cd build
    """ *
    opencl_cmake *
    raw"""
    install_license ${OPENCL_SRC}/LICENSE.txt
    """

    sources = [
        ArchiveSource(ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
        ArchiveSource(ROCM_GIT_CLR * "archive/rocm-$(version).tar.gz", GIT_TAGS_CLR[version]),
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
