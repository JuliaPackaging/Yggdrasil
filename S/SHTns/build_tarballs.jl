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
script = raw"""
cd $WORKSPACE/srcdir/shtns/
export CC="gcc"
export CFLAGS="-fPIC -O3" #only -fPIC produces slow code on linux x86 and MacOS x86 (maybe others)
# I remove openmp fftw checks, because FFTW_jll doesn't provide -lfftw3_omp
# propaly not the safest way!
sed -i -e '4908,4957d' configure 
./configure --prefix=${prefix} --host=${target} --enable-openmp
make -j${nproc}
make install
mkdir -p ${libdir}
gcc -fopenmp -shared -o "${libdir}/libshtns.${dlext}" *.o -lfftw3     
rm "${prefix}/lib/libshtns_omp.a"
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
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
                    julia_compat="1.6", 
                    # preferred_gcc_version=v"12", 
                    lock_microarchitecture=false,
                    )
