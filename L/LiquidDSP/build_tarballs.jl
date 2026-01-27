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

#cross-compiling outside of subset of platforms not achievable due to
#executable testing in cmake process
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} 

make -j${nproc}
make install

#need to specify license location
install_license ${WORKSPACE}/srcdir/liquid-dsp/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("i686", "linux"; libc = "glibc")
]


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
