# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ALPS"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/danielver02/ALPS.git", "220597dad7e94662368c3820f8b8d48b3e825cc2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ALPS
autoreconf -fi
 ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-blas="-L${prefix}/lib -lopenblas" --with-lapack="-L${prefix}/lib -lopenblas"
make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="OpenMPI_jll", uuid="fe0851c0-eecd-5654-98d4-656369965a5c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
