# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ICU"
version = v"76.1"
ygg_version = v"76.2"

# Collection of sources required to build ICU
sources = [
    GitSource("https://github.com/unicode-org/icu.git",
              "8eca245c7484ac6cc179e3e5f7c1ea7680810f39"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/icu

# Apply patch to link `libicudata` against the default standard libraries
# to avoid toolchain weirdness when you have a dynamic library that has
# _no_ dependencies (not even `libc`).  See this bug report for more:
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=653457
atomic_patch -p1 $WORKSPACE/srcdir/patches/yes_stdlibs.patch

cd icu4c

# Do the native build
(
    cp -r source/ native_build/
    cd native_build
    export CC="${CC_BUILD}"
    export CXX="${CXX_BUILD}"
    export AR="${AR_BUILD}"
    export LD="${LD_BUILD}"
    export RANLIB="${RANLIB_BUILD}"

    # See https://git.alpinelinux.org/aports/tree/main/icu/APKBUILD?id=334ebffde9dec34becdd628ad56007699e98ea81
    update_configure_scripts
    sed -i -e 's,DU_HAVE_STRTOD_L=1,DU_HAVE_STRTOD_L=0,' configure.ac
    sed -i -e 's,DU_HAVE_STRTOD_L=1,DU_HAVE_STRTOD_L=0,' configure
    for x in ARFLAGS CFLAGS CPPFLAGS CXXFLAGS FFLAGS LDFLAGS; do
        sed -i -e "/^${x} =.*/s:@${x}@::" "config/Makefile.inc.in"
    done

    ./configure --prefix=${prefix} --build=${MACHTYPE} \
        ac_cv_prog_ac_ct_AR=${AR} \
        ac_cv_prog_ac_ct_RANLIB=${RANLIB}
    make -j${nproc}
)

# Do the cross build
cd source

if [[ "${target}" == *-apple-* ]]; then
    # Do not append `-c` flag to ar, which isn't supported by LLVM's ar
    atomic_patch -p1 $WORKSPACE/srcdir/patches/argflags-no--c.patch
    export LDFLAGS="-headerpad_max_install_names"
fi

update_configure_scripts
./configure --prefix=${prefix} --host=${target} --target=${target} \
    --with-cross-build="/workspace/srcdir/icu/icu4c/native_build"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libicudata", "icudt$(version.major)"], :libicudata; dont_dlopen=true),
    LibraryProduct(["libicui18n", "icuin$(version.major)"], :libicui18n),
    LibraryProduct(["libicuio", "icuio$(version.major)"], :libicuio),
    LibraryProduct(["libicutest", "icutest$(version.major)"], :libicutest),
    LibraryProduct(["libicutu", "icutu$(version.major)"], :libicutu),
    LibraryProduct(["libicuuc", "icuuc$(version.major)"], :libicuuc),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
