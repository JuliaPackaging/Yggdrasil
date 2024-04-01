const NAME = "MIOpen"

const ROCM_GIT = "https://github.com/ROCmSoftwarePlatform/MIOpen/"
const GIT_TAGS = Dict(
    v"5.2.3" => "28747847446955b3bab24f7fc65c1a6b863a12f12ad3a35e0312072482d38122",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    # TODO add, when rocBLAS 5.2.3+ is built for musl
    # Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
const PRODUCTS = [
    LibraryProduct(["libMIOpen"], :libMIOpen, ["lib"]),
    FileProduct("include/half.hpp", :libhalf),
]

function configure_build(version)
    buildscript = raw"""
    mv ${WORKSPACE}/srcdir/half/include/half.hpp ${prefix}/include
    export HALF_INCLUDE_DIR=${prefix}/include

    mv ${WORKSPACE}/srcdir/rocm-clang* ${prefix}/llvm/bin

    cd ${WORKSPACE}/srcdir/MIOpen*/
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/boost-fix.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/disable-pch.patch
    mkdir build

    export AMDGPU_TARGETS="gfx900;gfx906;gfx90a;gfx1010;gfx1012;gfx1030"
    export ROCM_PATH=${prefix}

    export HIP_PATH=${prefix}/hip
    export HIP_PLATFORM=amd
    export HIP_RUNTIME=rocclr
    export HIP_COMPILER=clang

    CXXFLAGS="${CXXFLAGS} -I${prefix}/include/rocblas" \
    cmake -S . -B build \
        -DCMAKE_CXX_COMPILER=${prefix}/llvm/bin/rocm-clang++ \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_BUILD_TYPE=Release \
        -DROCM_PATH=${ROCM_PATH} \
        -DAMDGPU_TARGETS=${AMDGPU_TARGETS} \
        -DBoost_USE_STATIC_LIBS=OFF \
        -DMIOPEN_BACKEND=HIP \
        -DMIOPEN_USE_MLIR=OFF \
        -DHALF_INCLUDE_DIR=${HALF_INCLUDE_DIR}

    make -j${nproc} -C build install

    install_license ${WORKSPACE}/srcdir/MIOpen*/LICENSE.txt
    """

    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
        ArchiveSource(
            "https://downloads.sourceforge.net/project/half/half/2.1.0/half-2.1.0.zip",
            "ad1788afe0300fa2b02b0d1df128d857f021f92ccf7c8bddd07812685fa07a25";
            unpack_target="half"),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("HIP_jll"; compat=string(version)),
        Dependency("rocBLAS_jll"; compat=string(version)),
        Dependency("Zlib_jll"),
        Dependency("SQLite_jll"),
        Dependency("boost_jll"; compat="1.79.0"),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
