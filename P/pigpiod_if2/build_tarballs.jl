# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pigpiod_if2"
version = v"79"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/joan2937/pigpio.git", "c33738a320a3e28824af7807edafda440952c05d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pigpio/
atomic_patch -p1 ../patches/makefile.patch
make
make install prefix="${prefix}"
install_license UNLICENCE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpigpiod_if2", :libpigpiod_if2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
