const NAME = "hsakmt_roct"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "cc325d4b9a96062f2ad0515fce724a8c64ba56a7d7f1ac4a0753941b8599c52e",
    v"4.5.2" => "fb8e44226b9e393baf51bfcb9873f63ce7e4fcf7ee7f530979cf51857ea4d24b",
    v"5.2.3" => "8d313b8fd945a8d7248c00a2de9a2ee896fe77e464430a91b63400a986ec0bf0")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCT-Thunk-Interface*/

# fix for musl (but works on glibc too)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-Build-correctly-on-musl.patch"

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_C_FLAGS="-Dstatic_assert=_Static_assert" \
    -DBUILD_SHARED_LIBS=ON \
    ..

make -j${nproc}
make install
"""

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
        DirectorySource("./bundled"),
    ]
    products = [LibraryProduct(["libhsakmt"], :libhsakmt)]
    dependencies = [Dependency("NUMA_jll"), Dependency("libdrm_jll")]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, products, dependencies
end
