# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libfdk_aac"
# 3.0 is ABI compatible with 2.0 (libfdk-aac.so.2); dependents can use `compat="2.0.4, 3"`
version = v"3.0.0"

# Collection of sources required to build libfdk
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$(version).tar.gz",
                  "70b95857b958fb8f794489307a87845dde4cc1fcea060f3f29f40e4b2fe16c82"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fdk-aac-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
install_license NOTICE
install -Dvm 644 xhe-aac/NOTICE ${prefix}/share/licenses/${SRC_NAME}/NOTICE.xhe-aac
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfdk-aac", :libfdk),
    LibraryProduct("libfdk-xhe-aac", :libfdk_xhe),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# xhe-aac uses C99 for-loop declarations, which GCC 4.8 rejects in its default gnu90 mode
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
