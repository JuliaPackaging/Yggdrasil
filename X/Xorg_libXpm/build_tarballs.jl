# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xorg_libXpm"
version = v"3.5.13"

# Collection of sources required to complete build
sources = [
    "https://www.x.org/archive/individual/lib/libXpm-3.5.13.tar.bz2" =>
    "9cd1da57588b6cb71450eff2273ef6b657537a9ac4d02d0014228845b935ac25",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libXpm-3.5.13/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

# The products that we will ensure are always built
products = [
    LibraryProduct("libXpm", :libXpm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="X11_jll", uuid="546b0b6d-9ca3-5ba2-8705-1bc1841d8479")
    PackageSpec(name="Xorg_xproto_jll", uuid="46797783-dccc-5433-be59-056c4bde8513")
    PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

