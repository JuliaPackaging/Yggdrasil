using BinaryBuilder

name = "UserNSSandbox"
version = v"2021.04.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/staticfloat/Sandbox.jl",
              "0b1e9bac8eb109009ab63fda74c2015c31d0929f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Sandbox.jl/deps
mkdir -p ${bindir}
$CC -std=c99 -O2 -static -static-libgcc -g -o ${bindir}/sandbox ./userns_sandbox.c
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
