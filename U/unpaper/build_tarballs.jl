using BinaryBuilder

name = "unpaper"
version = v"7.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.flameeyes.com/files/unpaper-$(version).tar.xz",
                  "2575fbbf26c22719d1cb882b59602c9900c7f747118ac130883f63419be46a80"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unpaper-*

if [[ "${target}" == *-mingw* ]]; then
    # FFMPEG_jll installs the pkgconfig files in the wrong directory for Windows
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${libdir}/pkgconfig"
    # Give some hints to the linker
    export LDFLAGS="-L${libdir}"
    export LIBAV_LIBS="-lavformat -lavutil -lavcodec"
fi

apk add py3-sphinx

meson setup builddir --cross-file="${MESON_TARGET_TOOLCHAIN}"
meson compile -C builddir
meson install -C builddir

cd LICENSES
install_license 0BSD.txt Apache-2.0.txt GPL-2.0-only.txt MIT.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("unpaper", :unpaper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Offer a native xsltproc
    HostBuildDependency("XSLT_jll"),
    Dependency("FFMPEG_jll"; compat="8.0.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# FFMPEG uses `preferred_gcc_version=v"8"`.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
