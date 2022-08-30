# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SHTns"
version = v"3.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://bitbucket.org/nschaeff/shtns/downloads/shtns-$(version).tar.gz", "77f8a33b94df8786d2ce9b95cbfbe548f00443625b310b8c64012b22c8a7394f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shtns/
export CFLAGS="-fPIC"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
if [[ "${target}" == *-apple-* ]]; then
    # For some reasons, `configure` insists on setting CC2=gcc, also on macOS
    sed -i -e 's/gcc/cc/' -e 's/ -fno-tree-loop-distribute-patterns//' Makefile
fi
make -j${nproc}
make install
mkdir -p ${libdir}
cc -shared -o "${libdir}/libshtns.${dlext}" *.o -lfftw3
rm "${prefix}/lib/libshtns.a"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libshtns", :LibSHTns)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
