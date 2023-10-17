# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "boostpython"
version = v"1.79.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/boostorg/python.git", "8dd151177374dbf0aa5cb86bd350cf1ad13e2160")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/python
c++ -fPIC -o $libdir/libboost_python310.$dlext -O3 -shared -L$libdir -lpython3.10 -I$includedir -I$includedir/python3.10 $(find src ! -path src/numpy/\* -name \*.cpp)
cp -r include/* $includedir
install_license LICENSE_1_0.txt
"""

# No Windows support in Python_jll currently
platforms = filter(!Sys.iswindows, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libboost_python310", :libboost_python)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.79.0")
    Dependency(PackageSpec(name="Python_jll"), v"3.10.8"; compat="~3.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
