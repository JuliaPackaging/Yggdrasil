# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libassuan"
version = v"2.5.7"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$(version).tar.bz2",
                  "0103081ffc27838a2e50479153ca105e873d3d65d8a9593282e9c94c7e6afb76"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/libassuan-*

export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} "${FLAGS[@]}"
make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/libassuan-*/COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libassuan", "libassuan6"], :libassuan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"; compat="1.50.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
