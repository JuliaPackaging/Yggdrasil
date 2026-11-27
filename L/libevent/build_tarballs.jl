# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "libevent"
libevent_version =v"2.1.13"
# We add an offset because we updated our dependencies
version = v"2.1.16"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libevent/libevent/releases/download/release-$(libevent_version)-stable/libevent-$(libevent_version)-stable.tar.gz",
                  "f7e9383b8c0baa81b687e5b5eecc01beefaf1b19b64151d95ed61647fe7a315c"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libevent-*
if [[ "${target}" == aarch64-apple-* ]]; then
    # Build without `-Wl,--no-undefined`
    atomic_patch -p1 ../patches/build_with_no_undefined.patch
elif [[ "${target}" == *-mingw* ]]; then
     # Required to find OpenSSL
     export LDFLAGS="${LDFLAGS} -L${bindir}"
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
    LibraryProduct(["libevent", "libevent-$(version.major)-$(version.minor)"], :libevent),
    LibraryProduct(["libevent_core", "libevent_core-$(version.major)-$(version.minor)"], :libevent_core),
]
products_unix = [
    LibraryProduct(["libevent_pthreads", "libevent_pthreads-$(version.major)-$(version.minor)"], :libevent_pthreads),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

platforms_unix = filter(!Sys.iswindows, platforms)
platforms_windows = filter(Sys.iswindows, platforms)

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms_unix)))
    build_tarballs(ARGS, name, version, sources, script, platforms_unix, [products; products_unix], dependencies; julia_compat="1.6")
end
