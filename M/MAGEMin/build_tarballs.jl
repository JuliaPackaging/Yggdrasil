# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAGEMin"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ComputationalThermodynamics/MAGEMin/archive/refs/tags/v$(version).tar.gz", 
                  "91d48b1e6105985be62bad46a84795df02c06841"),
]

# Bash recipe for building across all platforms
script = raw"""
cd MAGEMin*
if [[ "${target}" == *-mingw* ]]; then
    MPI_LIBS="-lmsmpi"
else
    MPI_LIBS="-lmpi"
fi

CCFLAGS="-O3 -g -fPIC -std=c99"
LIBS="-L${libdir} -lm -lopenblas -lnlopt ${MPI_LIBS}"
INC="-I${includedir}"

# Compile library:
make -j${nproc} CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" lib

# compile binary
make -j${nproc} CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" all

install -Dvm 755 libMAGEMin.dylib "${libdir}/libMAGEMin.${dlext}"
install -vm 644 src/*.h "${includedir}"
install -Dvm 755 MAGEMin* "${bindir}/MAGEMin${exeext}"

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libMAGEMin", :libMAGEMin)
    ExecutableProduct("MAGEMin", :MAGEMin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms))
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
