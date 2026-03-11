using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libsemigroups"
version = v"3.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsemigroups/libsemigroups.git",
              "64b31f23d57ca36f613f2adc8525df36cd8bf2f2"),  # v3.5.1
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsemigroups

# Generate configure script
./autogen.sh
export CPPFLAGS="-I${prefix}/include"

# Disable HPCombi on all platforms
HPCOMBI_FLAG="--disable-hpcombi"

./configure --prefix=${prefix} \
            --build=${MACHTYPE} \
            --host=${target} \
            --enable-shared \
            --disable-static \
            ${HPCOMBI_FLAG}

# Build and install (V=1 for verbose link commands)
make V=1 -j${nproc}
make install

install_license LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

# These are the platforms we will build for by default
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsemigroups", :libsemigroups),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For the C++ compiler
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"10",
               clang_use_lld=false)
