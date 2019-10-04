# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Fontconfig"
version = v"2.13.1"

# Collection of sources required to build FriBidi
sources = [
    "https://www.freedesktop.org/software/fontconfig/release/fontconfig-$(version).tar.bz2" =>
    "f655dd2a986d7aa97e052261b36aa67b0a64989496361eca8d604e6414006741",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fontconfig-*/

apk add gperf

# Ensure that `${prefix}/include` is..... included
export CPPFLAGS="-I${prefix}/include"

if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FONTS_DIR="/usr/local/share/fonts"
elif [[ "${target}" == *-apple-* ]]; then
    FONTS_DIR="/System/Library/Fonts,/Library/Fonts,~/Library/Fonts,/System/Library/Assets/com_apple_MobileAsset_Font4,/System/Library/Assets/com_apple_MobileAsset_Font5"
fi

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-fix-config-linking.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0002-fix-mkdir.mingw.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0004-fix-mkdtemp.mingw.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0005-fix-setenv.mingw.patch"
autoreconf
./configure --prefix=$prefix --build=${MACHTYPE} --host=$target --disable-docs --with-add-fonts="${FONTS_DIR}"

# Disable tests
sed -i 's,all-am: Makefile $(PROGRAMS),all-am:,' test/Makefile

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libfontconfig", :libfontconfig)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "FreeType2_jll",
    "Bzip2_jll",
    "Zlib_jll",
    "Libuuid_jll",
    "Expat_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
