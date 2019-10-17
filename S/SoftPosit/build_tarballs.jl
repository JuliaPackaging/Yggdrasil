# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SoftPosit"
version = v"0.4.1"

# Collection of sources required to build SoftPosit
sources = [
    "https://gitlab.com/cerlane/SoftPosit/-/archive/$version/SoftPosit-$version.tar.gz" =>
    "13f7360c5b91ad3704f66537a754ba3748a764e1291eaa33940866ca37c7dbf5",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SoftPosit-*/build/Linux-x86_64-GCC/
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/makefile.patch"
make SLIB=".${dlext}" julia
install -Dm755 "softposit.${dlext}" "${libdir}/softposit.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("softposit", :softposit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
