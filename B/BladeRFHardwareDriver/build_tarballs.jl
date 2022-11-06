# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BladeRFHardwareDriver"
version = v"2.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Nuand/bladeRF.git", "0ffb795c450fe814060f95cd37455847c9c536d2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd bladeRF/host/
mkdir build
cd build
if [[ "${target}" == *86*-linux-gnu ]]; then
    export LDFLAGS="-lrt";
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DENABLE_BACKEND_LIBUSB=TRUE ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libbladeRF", :libbladerf),
    ExecutableProduct("bladeRF-fsk", :bladerf_fsk),
    ExecutableProduct("bladeRF-cli", :bladerf_cli)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll", uuid="a877fdc9-fe69-5ed6-b93d-11ecd0dc2d49"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
