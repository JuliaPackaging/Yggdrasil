# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibPQ"
version = v"14.1"
pg_version = string(version.major, '.', version.minor)
tzcode_version = "2021e"

# Collection of sources required to build LibPQ
sources = [
    ArchiveSource(
        "https://ftp.postgresql.org/pub/source/v$pg_version/postgresql-$pg_version.tar.gz",
        "b29030525e1314d676f41e6007a96d4489ba0d03fa93e67b477c1d5386790c8f"
    ),
    ArchiveSource(
        "https://data.iana.org/time-zones/releases/tzcode$tzcode_version.tar.gz",
        "584666393a5424d13d27ec01183da17703273664742e049d4f62f62dab631775",
    ),
    ArchiveSource(
        "https://kerberos.org/dist/krb5/1.19/krb5-1.19.3.tar.gz",
        "56d04863cfddc9d9eb7af17556e043e3537d41c6e545610778676cf551b9dcd0",
    ),
]

# Bash recipe for building across all platforms
# NOTE: readline and zlib are not used by libpq
script = raw"""
cd $WORKSPACE/srcdir
make CC=$BUILD_CC VERSION_DEPS= zic
export ZIC=$WORKSPACE/srcdir/zic
if [[ "${target}" == *"linux"* ]]; then
    ## We can only compile gss-api for linux
    cd krb5-1.19.3/src
    krb5_cv_attr_constructor_destructor=yes,yes  ac_cv_printf_positional=yes ac_cv_func_regcomp=yes ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
    make
    make install
    cd $WORKSPACE/srcdir/postgresql-*/
    if [[ "${target}" == i686-linux-musl ]]; then
        # Small hack: swear that we're cross-compiling.  Our `i686-linux-musl` is
        # bugged and it can run only a few programs, with the result that the
        # configure test to check whether we're cross-compiling returns that we're
        # doing a native build, but then it fails to run a bunch of programs during
        # other tests.
        sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
    fi
        ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-includes=$prefix/include --with-libraries=$prefix/lib --without-readline --without-zlib --with-openssl --with-gssapi
else
    cd /postgresql-*/
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-includes=$prefix/include --with-libraries=$prefix/lib --without-readline --without-zlib --with-openssl
fi
make -C src/interfaces/libpq install

install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpq", :LIBPQ_HANDLE)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
