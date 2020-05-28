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

echo "OMPFLAGS= -fopenmp" >> make.inc;
echo "OMPLIBS= -lgomp" >> make.inc;

echo "LIBS = -lm -lstdc++" >> make.inc;


echo "${TARGET}"

if [[ ${target} = *darwin* ]]; then

    # on mac needed a dylib not an so (make this cleaner later?)

    make -j${nproc} lib OMP=ON
    cd lib-static
    ar x libfmm3d.a
    ${FC} -dynamiclib -fPIC -fopenmp *.o -o libfmm3d.dylib -lm -lstdc++
    cd ..
    mv lib-static/libfmm3d.dylib lib/
    cp lib/libfmm3d.dylib ${libdir}/
    echo "copying libfmm3d.dylib to ${libdir}/libfmm3d.dylib"
    
elif [[ ${target} = *mingw* ]]; then

    # on windows needed a dll not an so (make this cleaner later?)

    echo "FFLAGS= -fPIC -O3 -fno-asynchronous-unwind-tables -march=native -funroll-loops" >> make.inc;
    make -j${nproc} lib OMP=ON
    cd lib-static
    ar x libfmm3d.a
    ${FC} -shared -fPIC -fopenmp *.o -o libfmm3d.dll -lm -lstdc++
    cd ..
    mv lib-static/libfmm3d.dll lib/
    cp lib/libfmm3d.dll ${libdir}/
    echo "copying libfmm3d.dll to ${libdir}/libfmm3d.dll"
    
else

    echo "LIBS = -lm -lstdc++" >> make.inc;
    echo "$(<make.inc)"
    make -j${nproc} lib OMP=ON
    cp lib/libfmm3d.so ${libdir}/
    echo "copying libfmm3d.so to ${libdir}/libfmm3d.so"

fi

install_license ${WORKSPACE}/srcdir/FMM3D/LICENSE
rm make.inc
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfmm3d", :libfmm3d)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;)
