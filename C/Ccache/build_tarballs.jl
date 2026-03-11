# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Ccache"
upstream_version = "4.9.1"
version = VersionNumber(upstream_version)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ccache/ccache/releases/download/v$(upstream_version)/ccache-$(upstream_version).tar.xz",
                  "4c03bc840699127d16c3f0e6112e3f40ce6a230d5873daa78c60a59c7ef59d25"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ccache*

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
install_license ../GPL-3.0.txt ../LGPL-3.0.txt
"""

# Install a newer SDK which supports `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ccache", :ccache),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # GCC 8 is actually required for full support of std::filesystem, but that
               # doesn't work with MinGW, but then with GCC 9 we run into
               #     [ 19%] Built target libhiredis_static
               #     /tmp/cchLGcal.s: Assembler messages:
               #     /tmp/cchLGcal.s:3360: Error: invalid register for .seh_savexmm
               #     /tmp/cchLGcal.s:3362: Error: invalid register for .seh_savexmm
               # (<https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65782>), which brings us to
               # GCC 10.
               julia_compat="1.6", preferred_gcc_version=v"10")
