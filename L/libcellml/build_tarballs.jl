using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libcellml"
version = v"0.7.0"

sources = [
    GitSource(
        "https://github.com/cellml/libcellml",
        "ac6ed5c348418e273e428a28ec156c0b14ec106b"),
]

# https://libcellml.org/documentation/installation/build_from_source
script = raw"""

if [ -d /workspace/MacOSX10.15.sdk/usr/local/lib/cmake/zlib/ ]; then
    ls /workspace/MacOSX10.15.sdk/usr/local/lib/cmake/zlib/
    cat /workspace/MacOSX10.15.sdk/usr/local/lib/cmake/zlib/ZLIBConfig.cmake
fi

if [ -d /opt/x86_64-unknown-freebsd13.4/x86_64-unknown-freebsd13.4/sys-root/usr/local/lib/cmake/zlib/ ]; then
    ls /opt/x86_64-unknown-freebsd13.4/x86_64-unknown-freebsd13.4/sys-root/usr/local/lib/cmake/zlib/
    cat /opt/x86_64-unknown-freebsd13.4/x86_64-unknown-freebsd13.4/sys-root/usr/local/lib/cmake/zlib/ZLIBConfig.cmake
fi

cmake -S libcellml -B build-libcellml-release \
    -DINSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TYPE=Release \
    -DTWAE=OFF \
    -DCOVERAGE=OFF \
    -DLLVM_COVERAGE=OFF \
    -DUNIT_TESTS=OFF

cmake --build build-libcellml-release
cmake --build build-libcellml-release --target install
install_license libcellml/LICENSE
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

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
