using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libcellml"
version = v"0.6.3"

sources = [
    GitSource(
        "https://github.com/cellml/libcellml",
        "7269e4a234b133e930722acd11acd04e4cad31b4"),
]

# https://libcellml.org/documentation/installation/build_from_source
script = raw"""
cd libcellml
mkdir build && cd build
cmake -DINSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TYPE=Release \
    -DTWAE=OFF \
    -DCOVERAGE=OFF \
    -DLLVM_COVERAGE=OFF \
    -DUNIT_TESTS=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

sources, script = require_macos_sdk("10.15", sources, script)

# It doesn't look like this works with 32-bit systems
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p->nbits(p)==32))

products = [
    LibraryProduct("libcellml", :libcellml)
]

dependencies = [
    # XML2 apparently had a breaking change, so it's important to specify the compat bound:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/9673#issuecomment-2434514026
    Dependency("XML2_jll"; compat="~2.13.4"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
