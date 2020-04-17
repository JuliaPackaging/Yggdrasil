# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xorg_libXpm"
version = v"3.5.13"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXpm-$(version).tar.bz2",
                  "9cd1da57588b6cb71450eff2273ef6b657537a9ac4d02d0014228845b935ac25"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXpm-*/
# We need a native xgettext
apk add gettext
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
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
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc")),
    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
