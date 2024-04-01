# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Elfutils"
version = v"0.189"

# Collection of sources required to build Elfutils
sources = [
    ArchiveSource("https://sourceware.org/elfutils/ftp/$(version.major).$(version.minor)/elfutils-$(version.major).$(version.minor).tar.bz2",
                  "39bd8f1a338e2b7cd4abc3ff11a0eddc6e690f69578a57478d8179b4148708c8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/elfutils-*/
if [[ ${target} = *-musl* ]] ; then
    for patchfile in $WORKSPACE/srcdir/patches/*; do
        atomic_patch -p1 $patchfile
    done
    cp $WORKSPACE/srcdir/error.h src/
    cp $WORKSPACE/srcdir/error.h lib/

    # install missing headers and `autopoint` 
    apk add bsd-compat-headers gettext-dev 
    # /usr/include isn't in search path of cross-cc, so copy cdefs.h
    mkdir -p $prefix/include/sys
    # Skip warning macro at top of file
    tail -n +2 /usr/include/sys/cdefs.h >$prefix/include/sys/cdefs.h
    autoreconf -vif
fi
export CC=gcc
export CXX=g++
CFLAGS="-Wno-error=unused-result" CPPFLAGS="-I${prefix}/include" ./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-debuginfod \
    --disable-libdebuginfod
make -j${nproc}
make install
rm -f "${includedir}/sys/cdefs.h"
install_license COPYING*
"""

# Only build for Linux
platforms = supported_platforms()
filter!(Sys.islinux, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libasm", :libasm),
    LibraryProduct("libdw", :libdw),
    LibraryProduct("libelf", :libelf),
    ExecutableProduct("eu-addr2line", :eu_addr2line),
    ExecutableProduct("eu-ar", :eu_ar),
    ExecutableProduct("eu-elfclassify", :eu_elfclassify),
    ExecutableProduct("eu-elfcmp", :eu_elfcmp),
    ExecutableProduct("eu-elfcompress", :eu_elfcompress),
    ExecutableProduct("eu-elflint", :eu_elflint),
    ExecutableProduct("eu-findtextrel", :eu_findtextrel),
    ExecutableProduct("eu-make-debug-archive", :eu_make_debug_archive),
    ExecutableProduct("eu-nm", :eu_nm),
    ExecutableProduct("eu-objdump", :eu_objdump),
    ExecutableProduct("eu-ranlib", :eu_ranlib),
    ExecutableProduct("eu-readelf", :eu_readelf),
    ExecutableProduct("eu-size", :eu_size),
    ExecutableProduct("eu-stack", :eu_stack),
    ExecutableProduct("eu-strings", :eu_strings),
    ExecutableProduct("eu-strip", :eu_strip),
    ExecutableProduct("eu-unstrip", :eu_unstrip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    # Future versions of bzip2 should allow a more relaxed compat because the
    # soname of the macOS library shouldn't change at every patch release.
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("XZ_jll"),
    Dependency("argp_standalone_jll"),
    Dependency("fts_jll"),
    Dependency("obstack_jll"; compat="~1.2.3"),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
