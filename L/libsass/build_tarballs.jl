# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libsass"
version = v"3.6.6"

# Collection of sources required to build SassBuilder
sources = [
    GitSource("https://github.com/sass/libsass.git", "7037f03fabeb2b18b5efa84403f5a6d7a990f460"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsass
autoreconf --force --install
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsass", :libsass_so),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7", clang_use_lld=false)
