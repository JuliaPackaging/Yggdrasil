using BinaryBuilder

name = "UserNSSandbox"
version = v"2021.01.19"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
mkdir -p ${bindir}
$CC -std=c99 -O2 -static -static-libgcc -g -o ${bindir}/sandbox ./sandbox.c
install_license /usr/share/licenses/MIT
"""

# We only build for Linux
platforms = filter(p -> Sys.islinux(p), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("sandbox", :sandbox),
]

# Dependencies that must be installed before this package can be built
build_tarballs(ARGS, name, version, sources, script, platforms, products, Dependency[])
