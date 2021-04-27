# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "YASM"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz", "3dce6601b495f5b3d45b59f7d2492a340ee7e84b5beca17e48f862502bd5603f")
]

# Bash recipe for building across all platforms
script = raw"""
# Set BINARY=32 on i686 platforms and armv7l
if [[ ${nbits} == 32 ]]; then
    export CFLAGS="$CFLAGS -m32"
    export LDFLAGS="$LDFLAGS -m32"
fi

cd $WORKSPACE/srcdir/yasm-*
autoreconf -f -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("yasm", :yasm),
    ExecutableProduct("ytasm", :ytasm),
    ExecutableProduct("vsyasm", :vsyasm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NASM_jll", uuid="08ca2550-6d73-57c0-8625-9b24120f3eae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
