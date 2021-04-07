using BinaryBuilder, Pkg

name = "Couenne"
version = v"0.5.8"

sources = [
    GitSource("https://github.com/coin-or/Couenne.git",
              "7154f7a9b3cd84be378d02b483d090b76fc79ce8"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Couenne

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch

if [[ ${target} == *mingw* ]]; then
    # Disable user-interrupts on Windows.
    sed -i s/'#define SIGNAL'// ${WORKSPACE}/srcdir/Couenne/Couenne/src/main/CouenneBab.cpp
    # Export symbols from DLL
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/export.patch
fi

# asl.h defines a macro called `filename`. Very unhelpful.
sed -i s/'#define filename'/'#define __asl_filename'/ /workspace/destdir/include/asl.h
sed -i s/'filename;'/'__asl_filename;'/ /workspace/srcdir/Couenne/Couenne/src/readnl/readnl.cpp

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
elif [[ ${target} == *apple* ]]; then
    # Turn off the annoying, but harmless, -Wdeprecated-register.
    export CPPFLAGS="${CPPFLAGS} -Wno-deprecated-register"
fi

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-static \
    --enable-shared \
    lt_cv_deplibs_check_method=pass_all \
    --with-asl-lib="-lasl -lipoptamplinterface" \
    --with-bonmin-lib="-lbonminampl -lbonmin -lipoptamplinterface -lipopt -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lasl -lopenblas"

make
make install
"""

platforms = supported_platforms()
platforms = filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libCouenne", :libcouenne),
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
