# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cohomCalg"
version = v"0.32"

sources = [
    GitSource("https://github.com/BenjaminJurke/cohomCalg",
              "c663c8e37cceab3cc0b2bcc57d35cb895930ab1f"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd cohomCalg*

atomic_patch -p1 ../patches/Makefile.patch
make -j${nproc}

# install
mkdir -p ${bindir}
cp bin/cohomcalg  ${bindir}
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cohomcalg", :cohomcalg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
#    Dependency("GMP_jll", v"6.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
