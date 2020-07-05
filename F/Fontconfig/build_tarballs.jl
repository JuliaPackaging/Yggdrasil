# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# TODO PR: Remove this line; this is a dummy change to trigger CI builds.

name = "Fontconfig"
version = v"2.13.1"

# Collection of sources required to build FriBidi
sources = [
    ArchiveSource("https://www.freedesktop.org/software/fontconfig/release/fontconfig-$(version).tar.bz2",
                  "f655dd2a986d7aa97e052261b36aa67b0a64989496361eca8d604e6414006741"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fontconfig-*/

apk add gperf

# Ensure that `${prefix}/include` is..... included
export CPPFLAGS="-I${prefix}/include"

FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-add-fonts="/usr/local/share/fonts")
    if [[ "${target}" == *-linux-* ]]; then
        FLAGS+=(--with-cache-dir="/var/cache/fontconfig")
    elif [[ "${target}" == *-freebsd* ]]; then
        FLAGS+=(--with-cache-dir="/var/db/fontconfig")
    fi
elif [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(--with-add-fonts="/System/Library/Fonts,/Library/Fonts,~/Library/Fonts,/System/Library/Assets/com_apple_MobileAsset_Font4,/System/Library/Assets/com_apple_MobileAsset_Font5")
fi

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-fix-config-linking.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0002-fix-mkdir.mingw.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0004-fix-mkdtemp.mingw.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0005-fix-setenv.mingw.patch"
autoreconf
./configure --prefix=$prefix --build=${MACHTYPE} --host=$target --disable-docs "${FLAGS[@]}"

# Disable tests
sed -i 's,all-am: Makefile $(PROGRAMS),all-am:,' test/Makefile

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfontconfig", :libfontconfig),
    ExecutableProduct("fc-cache", :fc_cache),
    ExecutableProduct("fc-cat", :fc_cat),
    ExecutableProduct("fc-conflist", :fc_conflist),
    ExecutableProduct("fc-list", :fc_list),
    ExecutableProduct("fc-match", :fc_match),
    ExecutableProduct("fc-pattern", :fc_pattern),
    ExecutableProduct("fc-query", :fc_query),
    ExecutableProduct("fc-scan", :fc_scan),
    ExecutableProduct("fc-validate", :fc_validate),
    FileProduct("etc/fonts/fonts.conf", :fonts_conf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libuuid_jll"),
    Dependency("Expat_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               init_block = """
ENV["FONTCONFIG_FILE"] = get(ENV, "FONTCONFIG_FILE", fonts_conf)
    ENV["FONTCONFIG_PATH"] = get(ENV, "FONTCONFIG_PATH", dirname(ENV["FONTCONFIG_FILE"]))
""")
