using BinaryBuilder

name = "libserialport"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sigrokproject/libserialport.git",
        "ffbfc5c76ba8100d21d0141478a6c0d761ecfb2f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libserialport/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-include-path=$prefix/include
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable FreeBSD for now, because hogweed needs alloca()?
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libserialport", :libserialport)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
