# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibPQ"
version = v"15.3"
pg_version = string(version.major, '.', version.minor)
tzcode_version = "2023c"

# Collection of sources required to build LibPQ
sources = [
    ArchiveSource(
        "https://ftp.postgresql.org/pub/source/v$pg_version/postgresql-$pg_version.tar.gz",
        "086d38533e28747966a4d5f1e78ea432e33a78f21dcb9133010ecb5189fad98c"
    ),
    ArchiveSource(
        "https://data.iana.org/time-zones/releases/tzcode$tzcode_version.tar.gz",
        "46d17f2bb19ad73290f03a203006152e0fa0d7b11e5b71467c4a823811b214e7",
    ),
]

# Bash recipe for building across all platforms
# NOTE: readline and zlib are not used by libpq
script = raw"""
cd $WORKSPACE/srcdir
make CC=$BUILD_CC VERSION_DEPS= zic
export ZIC=$WORKSPACE/srcdir/zic

# Fix "cannot find openssl" under Windows
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64/
    export OPENSSL_LIBS="-L${libdir} -lssl -lcrypto"
fi

cd $WORKSPACE/srcdir/postgresql-*/
if [[ "${target}" == i686-linux-musl ]]; then
    # Small hack: swear that we're cross-compiling.  Our `i686-linux-musl` is
    # bugged and it can run only a few programs, with the result that the
    # configure test to check whether we're cross-compiling returns that we're
    # doing a native build, but then it fails to run a bunch of programs during
    # other tests.
    sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
fi
FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-gssapi)
    if [[ "${target}" == *-freebsd* ]]; then
        # Only for FreeBSD we need to hint that we need to libcom_err to get
        # functions `add_error_table` and `remove_error_table`
        export LIBS=-lcom_err
    fi
fi
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-includes=${includedir} \
    --with-libraries=${libdir} \
    --without-readline \
    --without-zlib \
    --with-ssl=openssl \
    "${FLAGS[@]}"
make -C src/interfaces/libpq -j${nproc}
make -C src/interfaces/libpq install
make -C src/include install

# Delete static library
rm ${prefix}/lib/libpq.a
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
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("Kerberos_krb5_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")
