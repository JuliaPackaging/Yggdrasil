# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rr"
version = v"5.8"

# Collection of sources required to build rr
sources = [
    GitSource("https://github.com/JuliaLang/rr.git",
              "f5dd84c92672e7788a9e3fb58439507445683c93")
]

# Bash recipe for building across all platforms
script = raw"""
pip3 install pexpect
cd ${WORKSPACE}/srcdir/rr/

# our prehistorical glibc doesn't have prlimit
sed -i 's/#if defined (__i386__)/#if false/' src/record_signal.cc

mkdir build && cd build
PKG_CONFIG_LIBDIR=/workspace/destdir/lib/pkgconfig \
cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -Ddisable32bit=ON -DBUILD_TESTS=OFF -DWILL_RUN_TESTS=OFF -Dstaticlibs=ON ..
ninja -j${nproc}
ninja install
"""

# TODO: we should not set disable32bit=ON so that our 64-bit build support 32-bit traces.
#       sadly, our 64-bit toolchain doesn't support -m32...

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# rr only supports Linux
platforms = [
    Platform("i686", "linux", libc="glibc"),
    Platform("x86_64", "linux", libc="glibc"),
    Platform("aarch64", "linux", libc="glibc")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rr", :rr),
]

# Dependencies that must be installed before this package can be built
# This is really a build dependency
dependencies = [
    # For the capnp generator executable
    HostBuildDependency("capnproto_jll"),
    # For the capnp static support library
    BuildDependency("capnproto_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10")
