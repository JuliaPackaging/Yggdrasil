include("../common.jl")

name = "CXSparse"

sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
              "538273cfd53720a10e34a3d80d3779b607e1ac26"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir} -shared")
else
    FLAGS+=(UNAME="$(uname)")
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
fi

make -j${nproc} -C CXSparse "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
make -j${nproc} -C CXSparse "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"

install_license LICENSE.txt
"""

platforms = supported_platforms(;experimental=true)

dependencies = [
    Dependency("SuiteSparse_jll")
]

products = [
    LibraryProduct("libcxsparse", :libcxsparse)
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
