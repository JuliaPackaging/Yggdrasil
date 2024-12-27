using BinaryBuilder

# Collection of sources required to build Nettle
name = "Nettle"
version_string = "3.10"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/nettle/nettle-$(version_string).tar.gz",
                  "b4c518adb174e484cb4acea54118f02380c7133771e7e9beb98a0787194ee47c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nettle-*
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libnettle", :libnettle),
    LibraryProduct("libhogweed", :libhogweed),
    ExecutableProduct("nettle-hash", :nettle_hash)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC 7 to prevent errors on powerpc6ele:
#     poly1305-internal-2.s:180: Error: unrecognized opcode: `mtvsrdd'
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
