# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Liburing"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    # PR743: https://github.com/axboe/liburing/pull/743
    GitSource("https://github.com/cmazakas/liburing.git",
              "9e2890d35e9677d8cfc7ac66cdb2d97c48a0b5a2"),

    # FIXME revert to axboe/master when PR is merged...
    # GitSource("https://github.com/axboe/liburing.git", "??"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd liburing/
./configure --prefix=${prefix}
make -C src install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [
#    Platform("x86_64", "linux"; libc = "glibc"),
#    Platform("aarch64", "linux"; libc = "glibc")
#]
platforms = supported_platforms(;exclude=x->
    startswith(arch(x), r"arm|power") ||
    !Sys.islinux(x))


# The products that we will ensure are always built
products = [
    LibraryProduct("liburing-ffi", :liburing)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
