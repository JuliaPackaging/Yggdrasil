# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "picotool"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/raspberrypi/picotool.git", "f6fe6b7c321a2def8950d2a440335dfba19e2eab"),
    GitSource("https://github.com/raspberrypi/pico-sdk.git", "6a7db34ff63345a7badec79ebea3aaef1712f374")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/picotool/
cp udev/99-picotool.rules $prefix/99-picotool.rules
install_license LICENSE.TXT
mkdir build
cd build
PICO_SDK_PATH=$WORKSPACE/srcdir/pico-sdk cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_BUILD_TYPE=Release ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude= p -> !Sys.islinux(p) || libc(p) == "musl")

# The products that we will ensure are always built
products = [
    ExecutableProduct("picotool", :picotool),
    FileProduct("99-picotool.rules", :pico_udev)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll", uuid="a877fdc9-fe69-5ed6-b93d-11ecd0dc2d49"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"13")
