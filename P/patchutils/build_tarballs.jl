using BinaryBuilder

name = "patchutils"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/twaugh/patchutils",
              "00619c9315af6b7dab30ac7474fad917a815f591"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/patchutils*
./bootstrap
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# Windows needs some help
platforms = filter(!Sys.iswindows, supported_platforms())
products = [
    ExecutableProduct("lsdiff", :lsdiff),
]
dependencies = Dependency[]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
