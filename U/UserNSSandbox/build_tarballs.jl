using BinaryBuilder

name = "UserNSSandbox"
version = v"2021.04.22"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/staticfloat/Sandbox.jl",
              "0fc3812cd74a355e5a2c4d45d68fabb9fb059f55"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Sandbox.jl/deps
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
