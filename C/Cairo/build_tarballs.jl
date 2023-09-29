# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "Cairo"
version = v"1.18.0"

sources = [
    ArchiveSource("https://www.cairographics.org/releases/cairo-$(version).tar.xz",
                  "243a0736b978a33dee29f9cca7521733b78a65b5418206fef7bd1c3d4cf10b64"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairo-*/

if [[ "${target}" == *-mingw* ]]; then
    # Link against libssp to fix errors like
    #     /opt/x86_64-w64-mingw32/bin/../lib/gcc/x86_64-w64-mingw32/8.1.0/../../../../x86_64-w64-mingw32/bin/ld: .libs/cairo-output-stream.o: in function `memcpy':
    #     /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/string.h:202: undefined reference to `__memcpy_chk'
    #     /opt/x86_64-w64-mingw32/bin/../lib/gcc/x86_64-w64-mingw32/8.1.0/../../../../x86_64-w64-mingw32/bin/ld: .libs/cairo-win32-font.o: in function `memcpy':
    #     /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/string.h:202: undefined reference to `__memcpy_chk'
    #     /opt/x86_64-w64-mingw32/bin/../lib/gcc/x86_64-w64-mingw32/8.1.0/../../../../x86_64-w64-mingw32/bin/ld: .libs/cairo-pdf-interchange.o: in function `strcat':
    #     /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/string.h:234: undefined reference to `__strcat_chk'
    atomic_patch -p1 ../patches/mingw-libssp.patch
    # autoreconf needs gtkdocize, install it
    apk update
    apk add gtk-doc
    autoreconf -fiv
elif [[ "${target}" == "${MACHTYPE}" ]]; then
    # Remove system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
fi

# Because `zlib` doesn't have a proper `.pc` file, configure fails to find.
export CPPFLAGS="-I${includedir}"

# Delete old misleading libtool files
rm -f ${prefix}/lib/*.la

# if [[ "${target}" == *-apple-* ]]; then
#     BACKEND_OPTIONS="--enable-quartz --enable-quartz-image --disable-xcb --disable-xlib"
# elif [[ "${target}" == *-mingw* ]]; then
#     BACKEND_OPTIONS="--enable-win32 --disable-xcb --disable-xlib"
# elif [[ "${target}" == *-linux-* ]] || [[ "${target}" == *freebsd* ]]; then
#     BACKEND_OPTIONS="--enable-xlib --enable-xcb --enable-xlib-xcb"
# fi

mkdir output && cd output/
meson .. --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
    -Dfreetype=enabled \
    -Dtee=enabled \
    -Dpng=enabled \
    -Dzlib=enabled \
    -Dglib=enabled \
    -Ddefault_library=shared

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcairo-gobject", :libcairo_gobject),
    LibraryProduct("libcairo-script-interpreter", :libcairo_script_interpreter),
    LibraryProduct("libcairo", :libcairo),
]

# Some dependencies are needed only on Linux and FreeBSD
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
    Dependency("Glib_jll"),
    Dependency("Pixman_jll"),
    Dependency("libpng_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Xorg_libXext_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXrender_jll"; platforms=linux_freebsd),
    Dependency("LZO_jll"),
    Dependency("Zlib_jll"),
    # libcairo needs libssp on Windows, which is provided by CSL, but not in all versions of
    # Julia.  Note that above we're copying libssp to libdir for the versions of Julia where
    # this wasn't available.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
