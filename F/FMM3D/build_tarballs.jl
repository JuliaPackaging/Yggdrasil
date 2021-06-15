# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

# author: Travis Askham (askhamwhat@gmail.com)
#
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
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/FMM3D.git", "e42473a8091d33a83cbdb631cff4660ce7f94a96")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd FMM3D/

touch make.inc

# clang has some issue with openmp (lomp not found)
# force gcc
if [[ ${target} = *apple* || ${target} = *freebsd* ]]; then
  export CC="gcc"
fi

echo "CC=${CC}" >> make.inc;
echo "CXX=${CXX}" >> make.inc;
echo "FC=${FC}" >> make.inc;

if [[ ${target} = *mingw* ]]; then
    echo "FFLAGS= -fPIC -O3 -fno-asynchronous-unwind-tables -funroll-loops" >> make.inc;
else
    echo "FFLAGS= -fPIC -O3 -funroll-loops" >> make.inc;
fi

export OMPFLAGS="-fopenmp"
export OMPLIBS="-lgomp"
echo "OMPFLAGS= ${OMPFLAGS}" >> make.inc;
echo "OMPLIBS= ${OMPLIBS}" >> make.inc;

export LIBS="-lm -lgfortran"
echo "LIBS = ${LIBS}" >> make.inc;

make -j${nproc} lib OMP=ON

echo "${TARGET}"

# build the correct type of dynamic library for
# current target

export SHAREFLAGS="-shared -fPIC"

cd lib-static
ar x libfmm3d.a
${CC} ${SHAREFLAGS} ${OMPFLAGS} *.o -o "${libdir}/libfmm3d.${dlext}" ${LIBS} ${OMPLIBS}
cd ..

install_license ${WORKSPACE}/srcdir/FMM3D/LICENSE
rm make.inc
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(; experimental=true))
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm3d", :libfmm3d)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
