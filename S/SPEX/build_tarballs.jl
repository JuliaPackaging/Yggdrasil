using BinaryBuilder, Pkg

name = "SPEX"
version = v"3.0.0"

# Collection of sources required to build SuiteSparse:GraphBLAS
sources = [
    GitSource("https://github.com/clouren/SPEX",
        "1eaa6c79412d8efa9de76598344ea4d2c11be06a")
]

# Bash recipe for building across all platforms
script = raw"""
# Compile GraphBLAS
cd ${WORKSPACE}/srcdir/SPEX
CFLAGS="${CFLAGS} -std=c99"
cd ${WORKSPACE}/srcdir/SPEX/SPEX/SPEX_Util
if [[ "${target}" == *mingw* ]]; then
    make library -j${nproc} UNAME=Windows SO_OPTS="${SO_OPTS} -shared -L${libdir}"
else
    make library -j${nproc}
fi
cp ${WORKSPACE}/srcdir/SPEX/include/SPEX_Util.h ${includedir}
cp ${WORKSPACE}/srcdir/SPEX/lib/libspexutil* ${libdir}
cd ${WORKSPACE}/srcdir/SPEX/SPEX/SPEX_Left_LU
if [[ "${target}" == *mingw* ]]; then
    make library UNAME=Windows SO_OPTS="${SO_OPTS} -shared -L${libdir}"
else
    make library -j${nproc}
fi
cp ${WORKSPACE}/srcdir/SPEX/include/SPEX_Left_LU.h ${includedir}
cp ${WORKSPACE}/srcdir/SPEX/lib/libspexleftlu* ${libdir}
install_license ${WORKSPACE}/srcdir/SPEX/SPEX/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libspexutil", :libspexutil),
    LibraryProduct("libspexleftlu", :libspexleftlu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SuiteSparse_jll"),
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("MPFR_jll", v"4.1.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6")
