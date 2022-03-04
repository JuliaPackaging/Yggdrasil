# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libasyncns"
version = v"0.8.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://0pointer.de/lennart/projects/libasyncns/libasyncns-0.8.tar.gz", "4f1a66e746cbe54ff3c2fbada5843df4fbbbe7481d80be003e8d11161935ab74")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libasyncns-0.8
update_configure_scripts
ac_cv_func_malloc_0_nonnull=yes ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libasyncns", :libasyncns)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
