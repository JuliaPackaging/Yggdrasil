# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SoftPosit"
version = v"0.4.2"

# Collection of sources required to build SoftPosit
sources = [
    ArchiveSource("https://gitlab.com/cerlane/SoftPosit/-/archive/$version/SoftPosit-$version.tar.gz",
                  "03b796dbc3189e94fe81c4e730c673504161ad51562066211c51b5be943c0893"),
    DirectorySource("./bundled")
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
