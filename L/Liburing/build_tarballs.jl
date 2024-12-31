# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Liburing"
version = v"2.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/axboe/liburing.git", "80272cbeb42bcd0b39a75685a50b0009b77cd380"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/liburing
env prefix=${prefix} ./configure
make -C src install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [
#    Platform("x86_64", "linux"; libc = "glibc"),
#    Platform("aarch64", "linux"; libc = "glibc")
#]
#TODO platforms = supported_platforms(;exclude=x->
#TODO     startswith(arch(x), r"arm|power") ||
#TODO     !Sys.islinux(x))
platforms = supported_platforms(; exclude = !Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct("liburing-ffi", :liburing)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10.2.0")
