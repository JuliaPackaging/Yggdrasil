# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ICU"
version = v"67.1"

# Collection of sources required to build ICU
sources = [
    ArchiveSource("https://github.com/unicode-org/icu/releases/download/release-$(version.major)-$(version.minor)/icu4c-$(version.major)_$(version.minor)-src.tgz",
                  "94a80cd6f251a53bd2a997f6f1b5ac6653fe791dfab66e1eb0227740fb86d5dc"),
    DirectorySource("./bundled"),
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

# Do the cross build
cd source/

if [[ "${target}" == *-apple-* ]]; then
    # Do not append `-c` flag to ar, which isn't supported by LLVM's ar
    atomic_patch -p1 $WORKSPACE/srcdir/patches/argflags-no--c.patch
    export LDFLAGS="-headerpad_max_install_names"
fi

update_configure_scripts
./configure --prefix=$prefix --host=$target \
    --with-cross-build="/workspace/srcdir/icu/native_build"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libicudata", "icudt$(version.major)"], :libicudata),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

