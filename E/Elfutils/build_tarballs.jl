# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Elfutils"
version = v"0.196"

# Collection of sources required to build Elfutils
sources = [
    ArchiveSource("https://sourceware.org/elfutils/ftp/$(version.major).$(version.minor)/elfutils-$(version.major).$(version.minor).tar.bz2",
                  "fd5cc6b77ad6773cac93cb3f415f9318ac3b3455eecf801f6b4a742c4f6c7209"),
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

# The arm/aarch64 initreg backends include the raw kernel UAPI <linux/uio.h>
# after "system.h" has already pulled in glibc's <bits/uio.h> via <fcntl.h>.
# Neither header guards against the other on our sysroots, so `struct iovec`
# ends up defined twice.  They only need `struct iovec`, so use glibc's own
# <sys/uio.h>, which is properly guarded.
for f in backends/aarch64_initreg.c backends/arm_initreg.c; do
    sed -i -E 's|^#[[:space:]]*include[[:space:]]+<linux/uio\.h>|# include <sys/uio.h>|' "$f"
    if grep -q '<linux/uio\.h>' "$f"; then
        echo "ERROR: failed to replace <linux/uio.h> in $f" >&2
        exit 1
    fi
done

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
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("XZ_jll"),
    Dependency("argp_standalone_jll"),
    Dependency("fts_jll"),
    Dependency("obstack_jll"; compat="~1.2.3"),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
