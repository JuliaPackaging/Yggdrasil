# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAGEMin"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ComputationalThermodynamics/MAGEMin.git", "032116744f3df05b5a2999c2eb39689c831cf4c7"),
    ArchiveSource("https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.10.0.tar.gz", "328c1bea493a32cac5257d84157dc686cc3ab0b004e2bea22044e0a59f6f8a19"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lapack-*/LAPACKE/
cmake ../ -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLAPACKE=ON -DBUILD_SHARED_LIBS=ON
make lapacke -j${nproc}
make install

cd ../../MAGEMin/
if [[ "${target}" == *-mingw* ]]; then
    MPI_LIBS="-lmsmpi"
else
    MPI_LIBS="-lmpi"
fi
make CC=$CC CCFLAGS="-O3 -g -fPIC -std=c99" LIBS="-L${libdir} -lm -llapacke -lnlopt ${MPI_LIBS}" INC="-I${includedir}" lib
install -Dvm 755 libMAGEMin.dylib "${libdir}/libMAGEMin.${dlext}"
install -Dvm 644 src/*.h "${includedir}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libMAGEMin", :libMAGEMin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms))
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
