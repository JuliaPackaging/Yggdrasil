# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SharedMimeInfo"
version = v"2.4"

sources = [
    ArchiveSource("https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/$(version.major).$(version.minor)/shared-mime-info-$(version.major).$(version.minor).tar.bz2",
                  "32dc32ae39ff1c1bf8434dd3b36770b48538a1772bc0298509d034f057005992"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shared-mime-info-*
apk add gettext

meson setup builddir --cross-file="${MESON_TARGET_TOOLCHAIN}" -Dbuild-tests=false
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("update-mime-database", :update_mime_database),
    FileProduct("share/locale", :locale_dir),
]

# Dependencies that must be installed before this package can be built
# Based on http://www.linuxfromscratch.org/blfs/view/8.3/general/shared-mime-info.html
dependencies = [
    Dependency("Glib_jll"; compat="2.86.3"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Requires GCC 9 for std::filesystem.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
