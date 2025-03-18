# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "MAGEMin"
version = v"1.7.3"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/ComputationalThermodynamics/MAGEMin", 
                    "98ede02c4634a3bd0a1860d33f46a36be678ee98")                 ]

# Bash recipe for building across all platforms
script = raw"""
cd MAGEMin*

CCFLAGS="-O3 -g -fPIC -std=c99"

if [[ "${target}" == *-apple* ]]; then 
    # Use Accelerate for Lapack dependencies
    LIBS="-L${libdir} -lm -framework Accelerate -lnlopt"
    INC="-I${includedir}"
else
    LIBS="-L${libdir} -lm -lopenblas -lnlopt"
    INC="-I${includedir}"
fi

# Compile library:
make -j${nproc} CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" lib

# Compile binary
make -j${nproc} EXE_NAME="MAGEMin${exeext}" CC="${CC}" CCFLAGS="${CCFLAGS}" LIBS="${LIBS}" INC="${INC}" all

install -Dvm 755 libMAGEMin.dylib "${libdir}/libMAGEMin.${dlext}"
install -Dvm 755 MAGEMin${exeext} "${bindir}/MAGEMin${exeext}"

# store files
install -vm 644 src/*.h "${includedir}"

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> !(arch(p)  == "riscv64"), platforms)
platforms = filter(p -> !( (libgfortran_version(p) == v"3" || libgfortran_version(p) == v"4") && arch(p)=="powerpc64le"), platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libMAGEMin", :libMAGEMin)
    ExecutableProduct("MAGEMin", :MAGEMin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"); compat="=2.8.0")
    Dependency("OpenBLAS32_jll"; platforms=filter(!Sys.isapple, platforms))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
append!(dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
