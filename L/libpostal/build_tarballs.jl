# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpostal"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openvenues/libpostal.git", "8f2066b1d30f4290adf59cacc429980f139b8545")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpostal
flags=""

if [[ "${proc_family}" != "intel" ]]; then
    # SSE2 doesn't apply on ARM or PowerPC
    flags="${flags} --disable-sse2"
fi

# BinaryBuilder notes that the w64 binaries use the AVX2 instruction set. I haven't
# been able to fix this, as you can't use -march with BinaryBuilder, and -mno-avx2
# does not solve the problem.

./bootstrap.sh

# data download handled in Julia
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-data-download ${flags}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libpostal", :libpostal)
    # libpostal_data not available on Windows.
    #ExecutableProduct("libpostal_data", :libpostal_data)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
