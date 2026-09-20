# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Linux Studio Plugins (https://lsp-plug.in/), built as the CLAP bundle only.
# LGPL-3.0-or-later; the only GPL-3.0 files in the tree are Steinberg VST3
# headers under `modules/lsp-3rd-party/`, which a CLAP-only build never compiles.
name = "LSPPlugins"
version = v"1.2.35"

sources = [
    # The release tarball vendors under `modules/` the ~60 modules the git
    # repository fetches with `make fetch`, which a networkless sandbox cannot do.
    ArchiveSource("https://github.com/lsp-plugins/lsp-plugins/releases/download/$(version)/lsp-plugins-src-$(version).tar.gz",
                  "2c95ec7bb219d561ea3db36051b6c732133bcd76426fb836b1dd850dc4b5bb6c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lsp-plugins
install_license COPYING.LESSER COPYING

# FEATURES replaces the default list wholesale; `clap` alone drops `ui`, keeping
# X11, cairo, freetype, fontconfig and the GL stack out of the artifact.
make config \
    FEATURES="clap" \
    PREFIX="${prefix}" \
    LIBDIR="${libdir}" \
    ARCHITECTURE="${target%%-*}"

make -j${nproc}
make install
"""

# x86 Linux/glibc only: the build compiles resource-packer tools and *runs* them,
# so it works only where the builder can execute a target binary. Upstream
# `crosscompile` builds them with ${CXX_FOR_BUILD} (musl) instead, but the host
# code uses the glibc-only qsort_r/dlmopen and does not compile.
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
]

products = [
    # A .clap module is a plain shared object under a name LibraryProduct would not recognise.
    FileProduct("lib/clap/lsp-plugins.clap", :lsp_plugins_clap),
]

# The samplers and impulse-response plugins read audio files. The other four are
# libsndfile's pkg-config `Requires`, which `make config` resolves before proceeding.
dependencies = [
    Dependency("libsndfile_jll"; compat="1.2.2"),
    Dependency("FLAC_jll"; compat="1.4.4"),
    Dependency("libvorbis_jll"; compat="1.3.7"),
    Dependency("Ogg_jll"; compat="1.3.5"),
    Dependency("Opus_jll"; compat="1.3.3"),
]

# lock_microarchitecture=false: LSP sets a baseline -march per architecture
# itself, and each SIMD kernel is a separate TU with its own ISA flag plus
# runtime CPUID dispatch. preferred_gcc_version: the C++11 sources get no -std=
# flag, so the compiler's default dialect must be at least gnu++11.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", lock_microarchitecture=false,
               preferred_gcc_version=v"10")
