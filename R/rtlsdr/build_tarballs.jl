# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rtlsdr"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/osmocom/rtl-sdr.git", "b98c4a9c12dd722ef7a90b612ee2753aa9c456a6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rtl-sdr/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../
make -j ${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# freebsd not supported by libusb
platforms = filter!(!Sys.isfreebsd, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("librtlsdr", :librtlsdr)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll", uuid="a877fdc9-fe69-5ed6-b93d-11ecd0dc2d49"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
