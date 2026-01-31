# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LiquidDSP"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jgaeddert/liquid-dsp.git", "a8cc94a6f1f4386c294f5609dc2a373806cafd9c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/liquid-dsp

mkdir build
cd build 

#for i686 and x68_64 linux, can use native binarybuilder toolchain w/ simd
#enabled and executable testing. for all other linux, use toolchain but disable
#simd and any/all testing.  current linker error with windows and apple

if [[ "${target}" == *i686-linux* ]] || [[ "${target}" == *x86_64-linux* ]]; then
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release
else
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
             -DFIND_SIMD=OFF -DENABLE_SIMD=OFF \
             -DBUILD_EXAMPLES=OFF -DBUILD_AUTOTESTS=OFF -DBUILD_BENCHMARKS=OFF
fi


make -j${nproc}
make install

#need to specify license location
install_license ${WORKSPACE}/srcdir/liquid-dsp/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms( exclude=x->(Sys.isapple(x) || Sys.iswindows(x)) )


# The products that we will ensure are always built
products = [
    LibraryProduct("libliquid", :libliquid)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
