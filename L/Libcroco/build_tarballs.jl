# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libcroco"
version = v"0.6.13"

# Collection of sources required to build Libcroco
sources = [
    ArchiveSource("https://download.gnome.org/sources/libcroco/$(version.major).$(version.minor)/libcroco-$(version).tar.xz",
                  "767ec234ae7aa684695b3a735548224888132e063f92db585759b422570621d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcroco-*/

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    # We purposefully use an old binutils, so we must disable -Bsymbolic
    FLAGS+=(--disable-Bsymbolic)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-gtk-doc "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Experimental platforms cannot be used with Julia v1.5-.
# Change `julia_compat` to require at least Julia v1.6
# platforms = supported_platforms()
# Remove this when we build a newer version for which we can target the former
# experimental platforms
platforms = [
    # glibc Linuces
    Platform("i686", "linux"),
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv7l", "linux"),
    Platform("powerpc64le", "linux"),

    # musl Linuces
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),

    # BSDs
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),

    # Windows
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]


# The products that we will ensure are always built
products = [
    # Why must you flaunt the well-accepted ways of versioning your filename, libcroco?!
    # And even worse, why must you do so IN A SYNACTICALLY AMBIGUOUS MANNER?!
    LibraryProduct(["libcroco", "libcroco-$(version.major)", "libcroco-$(version.major).$(version.minor)"], :libcroco),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll", v"2.59.0"; compat="2.59"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

