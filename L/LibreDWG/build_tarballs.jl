# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibreDWG"
version = v"0.13.4"

# Collection of sources required to build LibreDWG. Upstream release
# tarball ships a pre-bootstrapped `configure`, so no autogen step is
# needed.
sources = [
    ArchiveSource("https://github.com/LibreDWG/libredwg/releases/download/$(version)/libredwg-$(version).tar.xz",
                  "7e153ea4dac4cbf3dc9c50b9ef7a5604e09cdd4c5520bcf8017877bbe1422cd5"),
]

# Bash recipe for building across all platforms.
#
# Flags chosen for the broadest production-grade JLL:
#   --enable-release           Production-stable build (skips unstable DWG
#                              features). Recommended for packagers per
#                              upstream README.
#   --enable-trace             Compiles in the LIBREDWG_TRACE env-var
#                              diagnostic hook. Default verbosity 0
#                              (silent), so zero runtime cost when off;
#                              operators get a path to debug parse
#                              failures without rebuilding.
#   --disable-bindings         Drops the Python/Perl/Lua/Ruby wrappers;
#                              Julia consumers use the C library + CLI
#                              tools only.
#   --disable-python           Paranoid pin against picking up host
#                              Python in the cross-compile rootfs.
#   --disable-docs             TeXinfo build chain is large; docs not
#                              shipped in the JLL.
#   --disable-werror           Tolerates warnings on cross toolchains.
#   --disable-static           Shared-only, matching JLL convention.
#
# CPPFLAGS export form (vs `--with-libiconv-prefix`) preserves libtool
# dep tracking for CLI tools on musl. Matches `L/LibArchive`, `L/libpsl`.
#
# `-Wno-error=implicit-function-declaration` for FreeBSD: LibreDWG calls
# `memmem` unguarded; FreeBSD hides the decl under `_POSIX_C_SOURCE`.
# Same workaround as `M/MPIR`, `P/PTSCOTCH`.
script = raw"""
cd $WORKSPACE/srcdir/libredwg-*/
export CPPFLAGS="-I${includedir}"
export CFLAGS="-Wno-error=implicit-function-declaration"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-release \
    --enable-trace \
    --disable-bindings \
    --disable-python \
    --disable-docs \
    --disable-werror \
    --disable-static
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# The products that we will ensure are always built.
products = [
    LibraryProduct("libredwg",   :libredwg),
    ExecutableProduct("dwg2dxf",    :dwg2dxf),
    ExecutableProduct("dxf2dwg",    :dxf2dwg),
    ExecutableProduct("dwgread",    :dwgread),
    ExecutableProduct("dwgwrite",   :dwgwrite),
    ExecutableProduct("dwgrewrite", :dwgrewrite),
    # `dwggrep` omitted: needs libpcre2-16, which Julia's stdlib PCRE2_jll lacks.
    ExecutableProduct("dwglayers",  :dwglayers),
    ExecutableProduct("dwgbmp",     :dwgbmp),
    ExecutableProduct("dwg2SVG",    :dwg2svg),
    # `dwg2ps` omitted: needs pslib, which has no JLL.
    ExecutableProduct("dxfwrite",   :dxfwrite),
]

# Dependencies that must be installed before this package can be built.
#   Libiconv_jll  codepage conversion (musl/windows/freebsd need the JLL;
#                 native on macOS/glibc, harmless to include unconditionally).
dependencies = [
    Dependency("Libiconv_jll"; compat="1.17"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
