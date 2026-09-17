# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Linux Studio Plugins (https://lsp-plug.in/), built as the CLAP bundle only:
# one `lsp-plugins.clap` module carrying the whole suite -- parametric and
# graphic equalisers, the compressor/expander/gate/limiter family including
# multiband and mid-side, crossovers, convolution reverb, delays, samplers.
#
# LGPL-3.0-or-later. Every module under `modules/` in the release tarball
# carries COPYING plus COPYING.LESSER, and README.md states LGPLv3; the only
# GPL-3.0 files in the tree are LSP's clean-room Steinberg VST3 interface
# headers under `modules/lsp-3rd-party/include/steinberg/`, which a CLAP-only
# build never compiles.
name = "LSPPlugins"
version = v"1.2.35"

# Collection of sources required to complete build
sources = [
    # The release source tarball rather than the git repository: the repository
    # fetches its ~60 modules with `make fetch` at build time, and a build
    # sandbox has no network. This tarball has them vendored under `modules/`.
    ArchiveSource("https://github.com/lsp-plugins/lsp-plugins/releases/download/$(version)/lsp-plugins-src-$(version).tar.gz",
                  "2c95ec7bb219d561ea3db36051b6c732133bcd76426fb836b1dd850dc4b5bb6c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/lsp-plugins
install_license COPYING.LESSER COPYING

# FEATURES replaces the default list wholesale, so naming only `clap` drops
# `ui` -- which is what keeps X11, cairo, freetype, fontconfig and the GL
# stack out of both the build and the artifact -- along with the standalone
# JACK/PipeWire hosts and the LADSPA/LV2/VST2/VST3 wrappers.
make config \
    FEATURES="clap" \
    PREFIX="${prefix}" \
    LIBDIR="${libdir}" \
    ARCHITECTURE="${target%%-*}"

make -j${nproc}
make install
"""

# x86 Linux/glibc only, and the reason is the build, not the sources.
#
# The build compiles two resource-packer tools (`respack`, `repository`) and
# *runs* them to generate the module's embedded resources. Without LSP's
# `crosscompile` feature those are built with the target toolchain, which works
# exactly when the builder can execute a target binary -- true for x86_64 and
# for i686 on an x86_64 builder, false everywhere else. With `crosscompile` they
# are built with `${CXX_FOR_BUILD}` instead, which is musl, and LSP's host code
# uses `qsort_r` and `dlmopen`: both glibc-only, so the host build does not
# compile at all. LSP itself supports aarch64, arm32 and riscv64, and adding
# them here needs either a glibc build toolchain or musl support upstream.
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
]

# The products that we will ensure are always built
products = [
    # A `.clap` module is a plain shared object under a name LibraryProduct
    # would not recognise, so it is declared as a file.
    FileProduct("lib/clap/lsp-plugins.clap", :lsp_plugins_clap),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # The sampler and the impulse-response plugins read audio files. The rest
    # are libsndfile's own pkg-config `Requires`, which `make config` resolves
    # before it will accept the configuration.
    Dependency("libsndfile_jll"; compat="1.2.2"),
    Dependency("FLAC_jll"; compat="1.4.4"),
    Dependency("libvorbis_jll"; compat="1.3.7"),
    Dependency("Ogg_jll"; compat="1.3.5"),
    Dependency("Opus_jll"; compat="1.3.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
#
# `lock_microarchitecture=false` because LSP's make system sets `-march` itself,
# per architecture, and every value it sets is that architecture's baseline:
# `-march=x86-64`, `-march=i586`, `-march=armv8-a`. The SIMD kernels are not
# built with `-march` at all -- each is a separate translation unit compiled
# with its own `-msse4.2`/`-mavx2`/`-mavx512f` and selected at runtime by CPUID,
# so the artifact stays baseline-portable.
#
# `preferred_gcc_version` because the sources are C++11 and LSP's make system
# does not pass `-std=`, so it needs a compiler whose default dialect is at
# least gnu++11; BinaryBuilder's oldest GCC defaults to gnu++98.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", lock_microarchitecture=false,
               preferred_gcc_version=v"10")
