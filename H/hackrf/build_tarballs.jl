# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "hackrf"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/greatscottgadgets/hackrf", "1cfe7dfe98d333450217d50e3f3a1ad0702e000f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hackrf/
mkdir host/build && cd host/build
cmake -B . -S .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j ${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# freebsd not supported by libusb
platforms = filter!(!Sys.isfreebsd, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libhackrf", :libhackrf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll")),
    Dependency(PackageSpec(name="FFTW_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
