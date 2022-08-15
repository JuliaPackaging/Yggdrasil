# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

# author: Travis Askham (askhamwhat@gmail.com)
#
#TODO: there does not appear to be a way to use gfortran
# with any openmp library other than libgomp.
#TODO: there are a number of stumbling points for the
# FAST_KER=ON option when cross-compiling. it is completely
# disabled for now. Some issues:
# - on musl, darwin, and freebsd various standard libraries
#   are not found
# - on mingw there is an invalid regiser error on x86_64 arch
# - generally, these seem to require a later version of gcc
#   but we would like to compile for various libgfortran
#   major versions

using BinaryBuilder, Pkg

name = "FMM3D"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/FMM3D.git", "9228240c090d1b8386617728ffa14372fe967b1a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FMM3D/

OMPFLAGS="-fopenmp"
OMPLIBS="-lgomp"

FFLAGS="-fPIC -O3 -funroll-loops -std=legacy"
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
ar x libfmm3d.a
${FC} ${SHAREFLAGS} ${OMPFLAGS} *.o -o "${libdir}/libfmm3d.${dlext}" ${LIBS} ${OMPLIBS}

install_license ${WORKSPACE}/srcdir/FMM3D/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm3d", :libfmm3d)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
