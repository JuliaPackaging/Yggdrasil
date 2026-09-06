# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libksba"
version = v"1.6.8"
ygg_version = v"1.6.9"          # Rebuilt for new architectures

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libksba/libksba-$(version).tar.bz2",
                  "0f4510f1c7a679c3545990a31479f391ad45d84e039176309d42f80cf41743f5"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/libksba-*
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} "${FLAGS[@]}"
make -j${nproc}
make install
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libksba", :libksba),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"; compat="1.58"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
