using BinaryBuilder

name = "UserNSSandbox"
version = v"2022.01.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/staticfloat/Sandbox.jl",
              "ed87f079edb1cef60c32ad5fbfbcd38c70a1314a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Sandbox.jl-cac5c095dfe27fa774bdad65957d45f476b220680c9a2038c0dd2c25cdd0b3e6/deps
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, Dependency[]; julia_compat="1.6")
