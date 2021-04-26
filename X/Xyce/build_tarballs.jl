# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
            GitSource("https://github.com/Xyce/Xyce.git", "a61faef4bfb2f36f1aa7cc44264bbbb66fbaac11"),
            DirectorySource("./bundled")
          ]

# Bash recipe for building across all platforms
script = raw"""
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}
cd $WORKSPACE/srcdir
apk add flex-dev
install_license ${WORKSPACE}/srcdir/Xyce/COPYING
cd Xyce
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross.patch
./bootstrap
cd ..
mkdir buildx
cd buildx
/workspace/srcdir/Xyce/./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared --disable-mpi \
    LDFLAGS="-L${libdir} -lopenblas" \
    CPPFLAGS="-I/${includedir} -I/usr/include"
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platform = [Platform("x86_64", "linux", libc="glibc", cxxstring_abi="cxx11", libgfortran_version=v"4.0.0")]

# The products that we will ensure are always built
products = [
    LibraryProduct("libADMS", :libADMS),
    LibraryProduct("libNeuronModels", :libNeuronModels),
    LibraryProduct("libxyce", :libxyce),
    ExecutableProduct("Xyce", :Xyce)
]

# Dependencies that must be installed before this package can be built
dependencies = [
                    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"))
                    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
                    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
                    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
                    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platform, products, dependencies; preferred_gcc_version = v"7.1.0")
