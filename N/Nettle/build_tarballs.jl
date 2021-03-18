using BinaryBuilder

# Collection of sources required to build Nettle
name = "Nettle"
version = v"3.5.1"
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/nettle/nettle-$(version).tar.gz",
                  "75cca1998761b02e16f2db56da52992aef622bf55a3b45ec538bc2eedadc9419"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nettle-*/
atomic_patch -p1 ../patches/alloca.patch

# Force c99 mode
export CFLAGS="${CFLAGS} -std=c99"

update_configure_scripts
./configure --prefix=$prefix --host=$target --with-include-path=$prefix/include
make -j${nproc}
make install
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libnettle", :libnettle),
    LibraryProduct("libhogweed", :libhogweed),
    ExecutableProduct("nettle-hash", :nettle_hash)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
