const NAME = "ROCmOpenCLRuntime"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime.git"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr.git"

const GIT_TAGS = Dict(
    v"4.2.0" => "549af90fdd3914b1d2a7304a78500a610c457891",
    v"4.5.2" => "bf77cab712343a85cc19abc13afcbfc5af4ceca5",
    v"5.2.3" => "40df4420ea9d0adc7a6e315a50305037c477b05d",
    v"5.4.4" => "00e0533578a588da2c0834c58d550e9379d17e49",
)
const GIT_TAGS_CLR = Dict(
    v"4.2.0" => "f343e8ffe98fbb6824400f5dbbff169e725c1165",
    v"4.5.2" => "307b17e49546864bcc257f476b1a88b6941e3bb8",
    v"5.2.3" => "442ede037c871420f3c810cb4228f5ebc2a133bb",
    v"5.4.4" => "ccd065214094837dd59a45aa5111d860aff38ecf",
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
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-disable-tls.patch
    """,
    v"4.5.2" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
    """,
    v"5.2.3" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
    """,
    v"5.4.4" => raw"""
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

    if version >= v"5.4-"
        rocdirs = raw"""
        export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr)
        export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime)
        """
    else
        rocdirs = raw"""
        export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
        export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)
        """
    end
    buildscript = rocdirs *
    raw"""
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
        GitSource(ROCM_GIT, GIT_TAGS[version]),
        GitSource(ROCM_GIT_CLR, GIT_TAGS_CLR[version]),
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
        Dependency("hsakmt_roct_jll"; compat=string(version)),
        Dependency("hsa_rocr_jll"; compat=string(version)),
        Dependency("ROCmDeviceLibs_jll"; compat=string(version)),
        Dependency("ROCmCompilerSupport_jll"; compat=string(version)),
        Dependency("Libglvnd_jll"),
        Dependency("Xorg_libX11_jll"),
        Dependency("Xorg_xorgproto_jll"),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, products, dependencies
end
