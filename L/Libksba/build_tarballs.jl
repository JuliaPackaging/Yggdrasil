# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libksba"
version = v"1.5.1"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libksba/libksba-$(version).tar.bz2",
                  "b0f4c65e4e447d9a2349f6b8c0e77a28be9531e4548ba02c545d1f46dc7bf921"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/libksba-*/
if [[ "${target}" == x86_64-*-mingw* ]]; then
    # `gpgrt-config` for this platform returns garbage results.  We replace it with
    # a simple wrapper around `pkg-config`, so that we can easily build the shared library.
    FLAGS=(GPG_ERROR_CONFIG="../gpgrt-config.sh" ac_cv_path_GPGRT_CONFIG="../gpgrt-config.sh")
fi
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
    # Future versions of `Libgpg_error_jll` maybe can have a more lax compat,
    # but the move 1.36 -> 1.42 changed the soname for FreeBSD and Windows.
    Dependency("Libgpg_error_jll", v"1.36.0"; compat="=1.36.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
