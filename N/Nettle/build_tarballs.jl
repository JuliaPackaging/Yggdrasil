using BinaryBuilder

# Collection of sources required to build Nettle
name = "Nettle"
version = v"3.7.2"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/nettle/nettle-$(version).tar.gz",
                  "8d2a604ef1cde4cd5fb77e422531ea25ad064679ff0adf956e78b3352e0ef162"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nettle-*/
atomic_patch -p1 ../patches/alloca.patch
# Include patch for finding definition of `AT_HWCAP2` within the Linux
# kernel headers, rather than the glibc headers, since our glibc is too old
atomic_patch -p1 ../patches/AT_HWCAP2-linux_headers.patch

# Force c99 mode
export CFLAGS="${CFLAGS} -std=c99"

update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-include-path=${includedir}
make -j${nproc} SUBDIRS="tools"
make install    SUBDIRS="tools"
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnettle", :libnettle),
    LibraryProduct("libhogweed", :libhogweed),
    ExecutableProduct("nettle-hash", :nettle_hash)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
