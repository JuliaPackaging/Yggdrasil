# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libzenohc"
version = v"1.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eclipse-zenoh/zenoh-c.git", "d70de64e007d471d54ead930dbe0df333372e679")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zenoh-c
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DZENOHC_CUSTOM_TARGET=$CARGO_BUILD_TARGET
cmake --build build --parallel ${nproc}
cmake --build build --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("powerpc64le", "linux"; libc = "glibc"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libzenohc", :libzenohc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"5.2.0")
