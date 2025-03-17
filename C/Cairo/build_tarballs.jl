# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "Cairo"
version = v"1.18.4"

sources = [
    ArchiveSource("https://cairographics.org/releases/cairo-1.18.4.tar.xz",
                  "445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairo*

# Add nipc_rmid_deferred_release = false for non linux builds to avoid running test
if [[ "${target}" != x86_64-linux-* ]]; then
    sed -i -e "s~cmake_defaults = .*~cmake_defaults = false\nipc_rmid_deferred_release = false~" ${MESON_TARGET_TOOLCHAIN}
elif [[ "${target}" == "${MACHTYPE}" ]]; then
    # Remove system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
fi

if [[ "${target}" == *-freebsd* ]]; then
    # Fix the error: undefined reference to `backtrace_symbols'
    sed -i -e "s~c_link_args = .*~c_link_args = ['-L${includedir}', '-lexecinfo']~" ${MESON_TARGET_TOOLCHAIN}
    sed -i -e "s~cpp_link_args = .*~cpp_link_args = ['-L${libdir}', '-lexecinfo']~" ${MESON_TARGET_TOOLCHAIN}
fi

mkdir output && cd output/


meson .. --cross-file=${MESON_TARGET_TOOLCHAIN} \
    -Dfreetype=enabled \
    -Dfontconfig=enabled \
    -Dtee=enabled \
    -Dpng=enabled \
    -Dzlib=enabled \
    -Dglib=enabled \
    -Ddefault_library=shared \
    -Dtests=disabled \
    -Ddwrite=disabled

if [[ "${target}" == *apple* ]]; then
    # Fix the error: undefined reference to `backtrace_symbols'
    sed -i -e "s~HAVE_CXX11_ATOMIC_PRIMITIVES~HAVE_OS_ATOMIC_OPS~" config.h
    echo "#define SIZEOF_VOID_P 8" >> config.h
    echo "#define HAVE_UINT64_T 1" >> config.h
    echo "#define HAVE_FT_SVG_DOCUMENT 1" >> config.h
fi

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
    Dependency("Pixman_jll"; compat="0.43.4"),
    Dependency("libpng_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Xorg_libXext_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXrender_jll"; platforms=linux_freebsd),
    # Build with LZO errors on macOS:
    # /workspace/destdir/include/lzo/lzodefs.h:2197:1: error: 'lzo_cta__3' declared as an array with a negative size
    Dependency("LZO_jll"; platforms=filter(!Sys.isapple, platforms)), 
    Dependency("Zlib_jll"),
    # libcairo needs libssp on Windows, which is provided by CSL, but not in all versions of
    # Julia.  Note that above we're copying libssp to libdir for the versions of Julia where
    # this wasn't available.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6", clang_use_lld=false)
