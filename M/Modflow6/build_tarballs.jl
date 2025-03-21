# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Modflow6"
version = v"6.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MODFLOW-ORG/modflow6.git",
        "056cf5c7283d63d1b57316535afcc63772860d5b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/modflow6*

meson -Dnetcdf=true --cross-file=${MESON_TARGET_TOOLCHAIN} builddir
meson compile -C builddir -j${nproc}
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmf6", :libmf6),
    ExecutableProduct("mf6", :mf6),
    ExecutableProduct("zbud6", :zbud6),
    ExecutableProduct("mf5to6", :mf5to6)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("NetCDFF_jll"; compat="4.6.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
