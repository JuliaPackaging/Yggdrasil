using Pkg
using BinaryBuilder

const NAME = "msgpack"
const GIT = "https://github.com/msgpack/msgpack-c.git"
const GIT_TAGS = Dict(
    "cpp-3.0.1" => "2c4f2b890ef1546fc022d270d11e657f6fc8022f",
)

const PLATFORMS = supported_platforms()
const PRODUCTS = [LibraryProduct(["libmsgpackc"], :libmsgpackc, ["lib"])]

function configure_build(version)
    tag = "cpp-$(string(version))"
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/msgpack*/
    mkdir build

    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DMSGPACK_BUILD_TESTS=OFF \
        -DMSGPACK_BUILD_EXAMPLES=OFF \
        -DCMAKE_BUILD_TYPE=Release
    make -j${nproc} -C build install

    install_license ${WORKSPACE}/srcdir/msgpack*/LICENSE_1_0.txt
    """

    sources = [GitSource(GIT, GIT_TAGS[tag])]
    dependencies = Dependency[]
    NAME, version, sources, buildscript, PLATFORMS, PRODUCTS, dependencies
end

build_tarballs(ARGS, configure_build(v"3.0.1")...; julia_compat="1.6")
