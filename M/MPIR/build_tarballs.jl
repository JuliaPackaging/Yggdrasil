# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPIR"
version = v"3.0.0"
ygg_version = v"3.0.2" # Fake version bump for compat

# Collection of sources required to build MPFRBuilder
sources = [
    GitSource("https://github.com/wbhart/mpir", "cdd444aedfcbb190f00328526ef278428702d56e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpir

apk add texinfo

./autogen.sh
./configure --enable-cxx --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#TODO platforms = supported_platforms(; exclude=p -> arch(p) != "x86_64" || Sys.isfreebsd(p))
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpir", :libmpir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("YASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
