using BinaryBuilder

name = "Glib"
version = v"2.86.0"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "b5739972d737cfb0d6fd1e7f163dfe650e2e03740bb3b8d408e4d1faea580d6d"),
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
               "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4"),
    FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
               "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX10.13.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX10.13.sdk/System MacOSX10.13.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=10.13
fi

if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir
    tar xjf ${WORKSPACE}/srcdir/mingw-w64-v10.0.0.tar.bz2
    cd mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install
fi

cd $WORKSPACE/srcdir/glib-*
install_license COPYING

# meson shouldn't be so opinionated (mesonbuild/meson#4542 is incomplete)
sed -i '/Werror=unused-command-line-argument/d' /usr/lib/python3.9/site-packages/mesonbuild/compilers/mixins/clang.py

if [[ "${target}" == *-freebsd* ]]; then
    # Adapt patch relative to `xattr` from
    # http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/devel/glib2/patches/patch-meson.build?rev=1.2&content-type=text/x-cvsweb-markup.
    # Quoting the comment:
    #     Don't fail if getxattr is not available. The code is already ready
    #     for this case with some small configure changes.
    atomic_patch -p1 ../patches/freebsd-have_xattr.patch
fi

mkdir build_glib && cd build_glib

MESON_FLAGS=(--cross-file="${MESON_TARGET_TOOLCHAIN}")
MESON_FLAGS+=(--buildtype=release)
MESON_FLAGS+=(-Dman=false)
MESON_FLAGS+=(-Dtests=false)

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtime. This flag allows having undefined symbols.
    MESON_FLAGS+=(-Db_lundef=false)
fi

if [[ "${target}" != *-mingw* ]]; then
    # on Windows, we can't build both static and shared libraries at the same time,
    # so stick to the shared one until we have a need for a static build
    MESON_FLAGS+=(--default-library both)
fi

meson "${MESON_FLAGS[@]}" ..

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc} --verbose
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgio-2", "libgio-2.0"], :libgio),
    LibraryProduct(["libglib-2", "libglib-2.0"], :libglib),
    LibraryProduct(["libgmodule-2", "libgmodule-2.0"], :libgmodule),
    LibraryProduct(["libgobject-2", "libgobject-2.0"], :libgobject),
    LibraryProduct(["libgthread-2", "libgthread-2.0"], :libgthread),
    LibraryProduct(["libgirepository-2", "libgirepository-2.0"], :libgirepository),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll"),
    Dependency("GettextRuntime_jll"; compat="0.22.4"),
    Dependency("Libffi_jll"; compat="~3.4.7"),
    Dependency("Libiconv_jll"),
    Dependency("Libmount_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("PCRE2_jll"; compat="10.42.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
