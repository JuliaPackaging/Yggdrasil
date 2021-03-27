using BinaryBuilder, Pkg

name = "Bonmin"
version = v"1.8.8"

sources = [
    GitSource("https://github.com/coin-or/Bonmin.git",
              "65c56cea1e7c40acd9897a2667c11f91d845bb7b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
./configure --enable-shared \
            --prefix=${prefix} \
            --host=${target}
make
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libbonmin", :libbonmin),
    ExecutableProduct("bonmin", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(; name="Ipopt_jll", version=v"3.14.4")),
    Dependency(PackageSpec(; name="Cbc_jll", version=v"2.10.5")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
