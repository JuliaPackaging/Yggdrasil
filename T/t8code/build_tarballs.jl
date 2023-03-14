# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "t8code"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/DLR-AMR/t8code/releases/download/v$(version)/t8code_v$(version).tar.gz", "01ceae6dd0ed596cf1abb5bc78caa77b5da94ca60d080aae3ccf0ba3c6464deb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd t8code/
./configure --enable-mpi CFLAGS=-O3 CXXFLAGS=-O3 CC=mpicc CXX=mpicxx --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libt8", :libt8),
    LibraryProduct("libsc", :libsc),
    LibraryProduct("libp4est", :libp4est)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="MPItrampoline_jll", uuid="f1f71cc9-e9ae-5b93-9b94-4fe0e1ad3748"))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"))
    Dependency(PackageSpec(name="OpenMPI_jll", uuid="fe0851c0-eecd-5654-98d4-656369965a5c"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
