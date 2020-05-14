# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Popt"
version = v"1.16.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://archive.ubuntu.com/ubuntu/pool/main/p/popt/popt_1.16.orig.tar.gz", "e728ed296fe9f069a0e005003c3d6b2dde3d9cad453422a10d6558616d304cc8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd popt-1.16/
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libpopt", :libpopt)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
