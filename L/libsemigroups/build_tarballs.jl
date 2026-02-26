using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libsemigroups"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsemigroups/libsemigroups.git",
              "6b63b74b37ad8d5fe0be82b3225e048d95b3eb2c"),  # v3.4.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsemigroups

# Generate configure script
./autogen.sh
export CPPFLAGS="-I${prefix}/include"

# Disable HPCombi on 32-bit platforms (requires __int128)
HPCOMBI_FLAG=""
if [[ "${nbits}" == 32 ]]; then
    HPCOMBI_FLAG="--disable-hpcombi"
fi

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
