using BinaryBuilder, Pkg

name = "FMM2D"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/fmm2d.git", "887907742394467587358a81a22b537edb58acf7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fmm2d/

OMPFLAGS="-fopenmp"
OMPLIBS="-lgomp"

FFLAGS="-fPIC -O3 -funroll-loops -std=legacy -w"
if [[ ${target} = *mingw* ]]; then
    FFLAGS="${FFLAGS} -fno-asynchronous-unwind-tables"
fi
LIBS="-lm"

echo "CC=${CC}" >> make.inc
echo "CXX=${CXX}" >> make.inc
echo "FC=${FC}" >> make.inc
echo "FFLAGS= ${FFLAGS}" >> make.inc
echo "OMPFLAGS= ${OMPFLAGS}" >> make.inc
echo "OMPLIBS= ${OMPLIBS}" >> make.inc
echo "LIBS = ${LIBS}" >> make.inc

make -j${nproc} lib OMP=ON

# build the correct type of dynamic library for
# current target
SHAREFLAGS="-shared -fPIC"

cd lib-static
ar x libfmm2d.a
${FC} ${SHAREFLAGS} ${OMPFLAGS} *.o -o "${libdir}/libfmm2d.${dlext}" ${LIBS} ${OMPLIBS}

install_license ${WORKSPACE}/srcdir/fmm2d/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm2d", :libfmm2d)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
