# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ICU"
version = v"65.1"

# Collection of sources required to build ICU
sources = [
    "https://github.com/unicode-org/icu/releases/download/release-$(version.major)-$(version.minor)/icu4c-$(version.major)_$(version.minor)-src.tgz" =>
    "53e37466b3d6d6d01ead029e3567d873a43a5d1c668ed2278e253b683136d948",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/icu/

# Do the native build
(
    cp -r source/ native_build/
    cd native_build
    CC="${CC_BUILD}"
    CXX="${CXX_BUILD}"
    AR="${AR_BUILD}"
    LD="${LD_BUILD}"
    RANLIB="${RANLIB_BUILD}"

    # See https://git.alpinelinux.org/aports/tree/main/icu/APKBUILD?id=334ebffde9dec34becdd628ad56007699e98ea81
    update_configure_scripts
    sed -i -e 's,DU_HAVE_STRTOD_L=1,DU_HAVE_STRTOD_L=0,' configure.ac
    sed -i -e 's,DU_HAVE_STRTOD_L=1,DU_HAVE_STRTOD_L=0,' configure
    for x in ARFLAGS CFLAGS CPPFLAGS CXXFLAGS FFLAGS LDFLAGS; do
        sed -i -e "/^${x} =.*/s:@${x}@::" "config/Makefile.inc.in"
    done

    ./configure --prefix=$prefix --build=${MACHTYPE} \
        ac_cv_prog_ac_ct_AR=${AR} \
        ac_cv_prog_ac_ct_RANLIB=${RANLIB}
    make -j${nproc}
)

# Don't use llvm-ar since ICU doesn't know how to deal with it
if [[ ${target} == *apple* ]] || [[ ${target} == *freebsd* ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi

# Do the cross build
cd source/
update_configure_scripts
./configure --prefix=$prefix --host=$target \
    --with-cross-build="/workspace/srcdir/icu/native_build"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libicudata", :libicudata),
    LibraryProduct("libicui18n", :libicui18n),
    LibraryProduct("libicuio", :libicuio),
    LibraryProduct("libicutest", :libicutest),
    LibraryProduct("libicutu", :libicutu),
    LibraryProduct("libicuuc", :libicuuc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
