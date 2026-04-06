# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SimpleBLE"
version = v"0.12.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simpleble/simpleble.git", "d1b7110644f0f9cb850d6ab43f7d461ca9d4031e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd simpleble/
cmake -S simplecble -B build_simplecble -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=TRUE
cmake --build build_simplecble --parallel ${nproc}
cd build_simplecble/
make install
exit
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
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libsimplecble", :simplecble)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
