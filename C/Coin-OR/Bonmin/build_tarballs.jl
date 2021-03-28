using BinaryBuilder, Pkg

name = "Bonmin"
version = v"1.8.8"

sources = [
    GitSource("https://github.com/coin-or/Bonmin.git",
              "65c56cea1e7c40acd9897a2667c11f91d845bb7b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Bonmin

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_dllexport.patch

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I$prefix/include/coin"
export CXXFLAGS="${CXXFLAGS} -std=c++11"

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
fi

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --with-asl-lib="-lasl -lipoptamplinterface"

make
make install
"""

platforms = supported_platforms()
platforms = filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbonmin", :libbonmin),
    ExecutableProduct("bonmin", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Cbc_jll", v"2.10.5"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll", v"3.13.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
