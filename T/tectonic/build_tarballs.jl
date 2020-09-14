# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tectonic"
version = v"0.1.15"

# Collection of sources required to build tar
sources = [
    ArchiveSource(
        "https://github.com/tectonic-typesetting/tectonic/archive/tectonic@$(version).tar.gz",
        "0e55188eafc1b58f3660a303fcdd6adc071051b9eb728119837fbeed2309914f"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tectonic-*/
cargo build --release
if [[ ${target} == *mingw* ]]; then
    cp target/${rust_target}/release/tectonic.exe $bindir/
else
    cp target/${rust_target}/release/tectonic $bindir/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("tectonic", :tectonic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Graphite2_jll"),
    Dependency("HarfBuzz_jll"),
    Dependency("ICU_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7")
