# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libevent"
libevent_version =v"2.1.12"
# We update to 2.1.13 because we updated our dependencies
version = v"2.1.13"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libevent/libevent/releases/download/release-$(libevent_version)-stable/libevent-$(libevent_version)-stable.tar.gz",
                  "92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libevent-*
if [[ "${target}" == aarch64-apple-* ]]; then
    # Build without `-Wl,--no-undefined`
    atomic_patch -p1 ../patches/build_with_no_undefined.patch
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
# FIXME: Name is `libevent-2-1-7.dll` but `parse_dl_name_version` strips the trailing `-7`
products = [
    LibraryProduct(["libevent", "libevent-2-1"], :libevent),
    LibraryProduct(["libevent_core", "libevent_core-2-1"], :libevent_core),
    LibraryProduct(["libevent_pthreads", "libevent_pthreads-2-1"], :libevent_pthreads),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
