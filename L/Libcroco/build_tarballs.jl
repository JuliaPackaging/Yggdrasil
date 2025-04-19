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
platforms = supported_platforms()

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
    # Updating to a newer XML2 version is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="2.0.0 - 2.13"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

