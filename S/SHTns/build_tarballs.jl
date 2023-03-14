# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SHTns"
version = v"3.5.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://bitbucket.org/nschaeff/shtns/downloads/shtns-$(version).tar.gz", "dc4ac08c09980e47c71d79d38696c5d1d631f86c2af1ce8aad5d21f7fd2c05b9")
]

# Bash recipe for building across all platforms
#if [[ "${target}" == *-apple-* ]]; then
    # For some reasons, `configure` insists on setting CC2=gcc, also on macOS
#    sed -i -e 's/gcc/cc/' -e 's/ -fno-tree-loop-distribute-patterns//' Makefile
#fi
#
script = raw"""
cd $WORKSPACE/srcdir/shtns/
export CFLAGS=" -DFFTW_PLAN_SAFE"
sed -i -e '4908,4957d' configure #removes openmp fftw checks, this is fine as we link to FFTW_jll
./configure --prefix=${prefix} --host=${target} --enable-openmp
make -j${nproc}
make install
mkdir -p ${libdir}
cc -shared -o "${libdir}/libshtns.${dlext}" *.o -lfftw3 
#rm "${prefix}/lib/libshtns_omp.a"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_microarchitectures(supported_platforms())
#platforms = expand_cxxstring_abis(expand_microarchitectures(supported_platforms(), ["x86_64", "avx", "avx2", "avx512"]))

# The products that we will ensure are always built
products = [
    LibraryProduct("libshtns", :LibSHTns)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6") #, preferred_gcc_version=v"11")

