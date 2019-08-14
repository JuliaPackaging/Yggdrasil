using BinaryBuilder

# Collection of sources required to build Gettext
name = "Gettext"
version = v"0.19.8"
sources = [
    "https://ftp.gnu.org/pub/gnu/gettext/gettext-$(version).tar.xz" =>
    "9c1781328238caa1685d7bc7a2e1dcf1c6c134e86b42ed554066734b621bd12f",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gettext-*/

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-Fix-linker-error-Cannot-export-rpl_printf.patch

autoreconf -f -i
./configure --prefix=$prefix --host=$target CFLAGS="-O2"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libgettext", :libgettext)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libiconv-v1.15-0/build_Libiconv.v1.15.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

