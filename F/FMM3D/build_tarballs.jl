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
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/FMM3D.git", "9228240c090d1b8386617728ffa14372fe967b1a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd FMM3D/

touch make.inc


echo "CC=${CC}" >> make.inc;
echo "CXX=${CXX}" >> make.inc;
echo "FC=${FC}" >> make.inc;

if [[ ${target} = *mingw* ]]; then
    echo "FFLAGS= -fPIC -O3 -fno-asynchronous-unwind-tables -funroll-loops -std=legacy" >> make.inc;
else
    echo "FFLAGS= -fPIC -O3 -funroll-loops -std=legacy" >> make.inc;
fi

export OMPFLAGS="-fopenmp"
export OMPLIBS="-lgomp"

# openmp library name is different on bsd systems
if [[ ${target} = *apple* || ${target} = *freebsd* ]]; then
  export OMPLIBS="-lomp"
fi


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

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm3d", :libfmm3d)
]

# Dependencies that must be installed before this package can be built
# Borrowed from recipe for libblis (B/blis)
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
