# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P4est"
version = v"2.3.1"


# Collection of sources required to complete build
sources = [
    ArchiveSource("https://p4est.github.io/release/p4est-2.3.1.tar.gz", "be66893b039fb3f27aca3d5d00acff42c67bfad5aa09cea9253cdd628b2bdc9a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd p4est-*
if [[ "${target}" == *-freebsd* ]]; then
  export LIBS="-lm"
elif [[ "${target}" == x86_64-linux-musl ]]; then
  # We can't run Fortran programs for the native platform, so a check that the
  # Fortran compiler works would fail.  Small hack: swear that we're
  # cross-compiling.  See:
  # https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/50.
  sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
  sed -i 's/cross_compiling=no/cross_compiling=yes/' sc/configure
fi

# Set default preprocessor and linker flags
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

# Special Windows treatment
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
  # Set linker flags only at build time (see https://docs.binarybuilder.org/v0.3/troubleshooting/#Windows)
  FLAGS+=(LDFLAGS="$LDFLAGS -no-undefined")

  # Add manual definitions to fix missing `htonl` according to `INSTALL_WINDOWS` file
  # (see https://github.com/cburstedde/p4est/blob/master/INSTALL_WINDOWS)
  sed -i "1s/^/#define htonl(_val) ( ((uint16_t)(_val) \& 0xff00) >> 8 | ((uint16_t)(_val) \& 0xff) << 8 )\n/" src/p4est_algorithms.c src/p8est_algorithms.c src/p6est.c src/p4est_ghost.c
fi

# Configure, build, install
# Note: BLAS is disabled since it is only needed for SC if it is used outside of p4est
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --without-blas
make -j${nproc} "${FLAGS[@]}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libp4est", :libp4est),
    LibraryProduct("libsc", :libsc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
