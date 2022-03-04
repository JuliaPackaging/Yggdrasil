# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msolve"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.lip6.fr/safey/msolve.git", "85071af5929fddfe9e15ea60831088d072dbf28b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd msolve/
./autogen.sh

if [[ "${target}" == *-apple-* ]]; then
    export CC=gcc
fi
export CPPFLAGS="-I${includedir}"

ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes ./configure --with-gnu-ld --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(!Sys.iswindows, platforms)  # no FLINT_jll available

# The products that we will ensure are always built
products = [
    LibraryProduct("libmsolve", :libmsolve),
    LibraryProduct("libneogb", :libneogb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("FLINT_jll", compat = "~200.800.401"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2")
