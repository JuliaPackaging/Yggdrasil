# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Wigxjpf"
version = v"1.11.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://fy.chalmers.se/subatom/wigxjpf/wigxjpf-latest.tar.gz", "5d078bbbf87c917d0df3c5e2204cbd8a51041517630ac84bdca728611ea2f12f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wigxjpf-1.11

mkdir -p $WORKSPACE/destdir/lib
mkdir -p $WORKSPACE/destdir/bin
mkdir -p $WORKSPACE/destdir/shared/licenses

if [ "$(uname)" == "Darwin" ]; then
    make lib/libwigxjpf_shared.dylib
    cp lib/libwigxjpf_shared.dylib $WORKSPACE/destdir/lib/  
else
    make lib/libwigxjpf_shared.so
    cp lib/libwigxjpf_shared.so $WORKSPACE/destdir/lib/
    cp lib/libwigxjpf_shared.so $WORKSPACE/destdir/bin/libwigxjpf_shared.dll
fi

cp README $WORKSPACE/destdir/shared/licenses/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libwigxjpf_shared", :wigxjpf)
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
