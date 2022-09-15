using BinaryBuilder, Pkg

name = "SPEX"
version = v"1.1.5"

# Collection of sources required to build SuiteSparse:GraphBLAS
sources = [
    GitSource("https://github.com/clouren/SPEX",
        "9471682b072419063d73bc950949bf3458b187f9")
]

# Bash recipe for building across all platforms
script = raw"""
# Compile GraphBLAS
cd ${WORKSPACE}/srcdir/SPEX
CFLAGS="${CFLAGS} -std=c99"
make -j${nproc}
cp lib/libspex* ${libdir}
cp include/SPEX* ${includedir}
install_license SPEX/SPEX_Left_LU/License/lesserv3.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libspexutil", :libspexutil),
    LibraryProduct("libspexleftlu", :libspexleftlu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SuiteSparse_jll"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6")
