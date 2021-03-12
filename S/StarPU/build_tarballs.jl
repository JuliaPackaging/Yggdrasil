# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "StarPU"
version = v"1.3.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://files.inria.fr/starpu/starpu-1.3.7/starpu-1.3.7.tar.gz", "1d7e01567fbd4a66b7e563626899374735e37883226afb96c8952fea1dab77c2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd starpu*
mkdir build
cd build
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-fortran
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libstarpu", :libstarpu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0")
