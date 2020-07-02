# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibPQ"
version = v"12.3"
pg_version = string(version.major, '.', version.minor)
tzdata_version = "2020a"

# Collection of sources required to build LibPQ
sources = [
    ArchiveSource(
        "https://ftp.postgresql.org/pub/source/v$pg_version/postgresql-$pg_version.tar.gz",
        "708fd5b32a97577679d3c13824c633936f886a733fc55ab5a9240b615a105f50"
    ),
    ArchiveSource(
        "https://data.iana.org/time-zones/releases/tzdata$tzdata_version.tar.gz",
        "547161eca24d344e0b5f96aff6a76b454da295dc14ed4ca50c2355043fb899a2",
    ),
    ArchiveSource(
        "https://data.iana.org/time-zones/releases/tzcode$tzdata_version.tar.gz",
        "7d2af7120ee03df71fbca24031ccaf42404752e639196fe93c79a41b38a6d669",
    ),
]

# Bash recipe for building across all platforms
# NOTE: readline and zlib are not used by libpq
script = raw"""
cd $WORKSPACE/srcdir
make CC=$BUILD_CC
export ZIC=$WORKSPACE/srcdir/zic
cd postgresql-*/
if [[ "${target}" == i686-linux-musl ]]; then
    # Small hack: swear that we're cross-compiling.  Our `i686-linux-musl` is
    # bugged and it can run only a few programs, with the result that the
    # configure test to check whether we're cross-compiling returns that we're
    # doing a native build, but then it fails to run a bunch of programs during
    # other tests.
    sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
fi
./configure --prefix=$prefix --host=$target --with-includes=$prefix/include --with-libraries=$prefix/lib --without-readline --without-zlib --with-openssl
make -C src/interfaces/libpq install
install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpq", :LIBPQ_HANDLE)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
