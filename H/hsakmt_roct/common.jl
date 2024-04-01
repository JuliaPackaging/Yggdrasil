const NAME = "hsakmt_roct"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "7cdd63475c36bb9f49bb960f90f9a8cdb7e80a21",
    v"4.5.2" => "3277d5354ed623598a5cea82cc3790a577af177c",
    v"5.2.3" => "026fae434a141faa10da109a2c1b03dc9e06db3f",
    v"5.4.4" => "2d55276bfa186a47611cdd2fc20879dacb506a9a",
    v"5.5.1" => "695ec62187ba0708e3f8a960c2b75b877c2521a9",
)
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

install_license ${WORKSPACE}/srcdir/ROCT-Thunk-Interface*/LICENSE.md
"""

function configure_build(version)
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
        DirectorySource("./bundled"),
    ]
    products = [LibraryProduct(["libhsakmt"], :libhsakmt)]
    dependencies = [Dependency("NUMA_jll"), Dependency("libdrm_jll")]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, products, dependencies
end
