# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FMM3D"
version = v"0.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/FMM3D.git", "2fd129984e48abe437fddd12013dc434563a773a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd FMM3D/

touch make.inc

echo "CC=${CC}" >> make.inc;
echo "CXX=${CXX}" >> make.inc;
echo "FC=${FC}" >> make.inc;

echo "FFLAGS= -fPIC -O3 -march=native -funroll-loops" >> make.inc;

# check if non Intel architecture (get rid of march native)
if [[ ${proc_family} != intel ]]; then
    echo "FFLAGS= -fPIC -O3 -funroll-loops" >> make.inc;
fi

echo "CXXFLAGS= -std=c++11 -DSCTL_PROFILE=-1" >> make.inc;
echo "CXXFLAGS+=\$(FFLAGS)" >> make.inc;

echo "OMPFLAGS =-fopenmp" >> make.inc;
echo "OMPLIBS =-lgomp" >> make.inc;

# check if musl (fast_ker option seems broken, stddef not found?)
# might be fixable. for now, kill fast_ker
if [[ ${target} == *musl* ]]; then
    echo "LIBS = -lm -lstdc++" >> make.inc;
    make lib OMP=ON
else
    echo "LIBS = -lm -lstdc++" >> make.inc;
    make lib OMP=ON FAST_KER=ON
fi

install_license ${WORKSPACE}/srcdir/FMM3D/LICENSE
cp lib/libfmm3d.so $prefix/lib/
rm make.inc
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
#platforms = expand_gfortran_versions(platforms)
#platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm3d", :libfmm3d)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0")
