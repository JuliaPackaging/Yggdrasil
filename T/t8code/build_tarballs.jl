# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "t8code"
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/DLR-AMR/t8code/releases/download/v$(version)/t8code_v$(version).tar.gz", "561f7e24238b2c81dc8299351e2643be29648cd01b6dcf960bb12f8cec9e0c15")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd t8code/

# Set default preprocessor and linker flags
# Note: This is *crucial* for Windows builds as otherwise the wrong libraries are picked up!
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export CFLAGS="-O3 -std=c99"
export CXXFLAGS="-O3 -std=c++11"

# Set necessary flags for FreeBSD
if [[ "${target}" == *-freebsd* ]]; then
  export LIBS="-lm"
fi

# Set necessary flags for Windows and non-Windodws systems
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
  # Set linker flags only at build time (see https://docs.binarybuilder.org/v0.3/troubleshooting/#Windows)
  FLAGS+=(LDFLAGS="$LDFLAGS -no-undefined")
  # Configure does not find the correct Fortran compiler
  export F77="f77"
  # Link against ws2_32 to use the htonl function from winsock2.h
  export LIBS="-lmsmpi -lws2_32"
  # Disable MPI I/O on Windows since it causes p4est to crash
  mpiopts="--enable-mpi --disable-mpiio"
  # Linker looks for libmsmpi instead of msmpi, copy existing symlink
  cp -d ${libdir}/msmpi.dll ${libdir}/libmsmpi.dll
else
  # Use MPI including MPI I/O on all other platforms
  export CC="mpicc"
  export CXX="mpicxx"
  mpiopts="--enable-mpi"
fi

# Run configure
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --without-blas ${mpiopts}

# Build & install
make -j${nproc} "${FLAGS[@]}"
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
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("x86_64", "windows"; )
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
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
