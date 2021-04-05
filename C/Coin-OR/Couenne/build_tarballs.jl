using BinaryBuilder, Pkg

name = "Couenne"
version = v"0.5.8"

sources = [
    GitSource("https://github.com/coin-or/Couenne.git",
              "7154f7a9b3cd84be378d02b483d090b76fc79ce8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Couenne

# Remove misleading libtool files
rm -f ${libdir}/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin -I${includedir}/coin-or"
export CXXFLAGS="${CXXFLAGS} -std=c++11"

if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
    export LT_LDFLAGS="-no-undefined"
fi

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-static \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl -lipoptamplinterface" \
    --with-bonmin-lib="-lCoinUtils -lClp -lCgl -lCbc -lbonmin -lbonminampl"

make
make install
"""

platforms = supported_platforms()
platforms = filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)
# platforms = expand_gfortran_versions(platforms)
# platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("couenne", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", v"0.1.2"),
    Dependency("Bonmin_jll", v"1.8.8"),
    Dependency("Cbc_jll", v"2.10.5"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll", v"3.13.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
