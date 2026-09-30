# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Linux Studio Plugins (https://lsp-plug.in/), CLAP bundle only. LGPL-3.0-or-later;
# the only GPL files are VST3 headers a CLAP-only build never compiles.
name = "LSPPlugins"
version = v"1.2.35"

sources = [
    # Release tarball vendors the modules the repo would `make fetch` at build time.
    ArchiveSource("https://github.com/lsp-plugins/lsp-plugins/releases/download/$(version)/lsp-plugins-src-$(version).tar.gz",
                  "2c95ec7bb219d561ea3db36051b6c732133bcd76426fb836b1dd850dc4b5bb6c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lsp-plugins
install_license COPYING.LESSER COPYING

# `clap` alone drops `ui`, and with it X11/cairo/freetype/fontconfig/GL.
make config \
    FEATURES="clap" \
    PREFIX="${prefix}" \
    LIBDIR="${libdir}" \
    ARCHITECTURE="${target%%-*}"

make -j${nproc}
make install
"""

# x86/glibc only: the build runs resource-packer tools it compiles, and
# `crosscompile` builds them against musl, which lacks qsort_r/dlmopen.
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
]

products = [
    # A .clap module is a shared object under a name LibraryProduct would not match.
    FileProduct("lib/clap/lsp-plugins.clap", :lsp_plugins_clap),
]

# The codec deps are libsndfile's pkg-config `Requires`, resolved by `make config`.
dependencies = [
    Dependency("libsndfile_jll"; compat="1.2.2"),
    Dependency("FLAC_jll"; compat="1.4.4"),
    Dependency("libvorbis_jll"; compat="1.3.7"),
    Dependency("Ogg_jll"; compat="1.3.5"),
    Dependency("Opus_jll"; compat="1.3.3"),
]

# lock_microarchitecture=false: LSP sets a baseline -march itself and dispatches
# SIMD via per-TU ISA flags + CPUID. GCC 10: C++11 sources with no -std= flag.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", lock_microarchitecture=false,
               preferred_gcc_version=v"10")
