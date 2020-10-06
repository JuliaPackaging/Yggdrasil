# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P4est"
version = v"2.2.0"


# Collection of sources required to complete build
sources = [
    ArchiveSource("https://p4est.github.io/release/p4est-2.2.tar.gz", "1549cbeba29bee2c35e7cc50a90a04961da5f23b6eada9c8047f511b90a8e438"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p4est-2.2/
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
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export BLAS_LIBS="${libdir}/libopenblas.${dlext}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)


# The products that we will ensure are always built
products = [
    LibraryProduct("libp4est", :libp4est),
    LibraryProduct("libsc", :libsc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
