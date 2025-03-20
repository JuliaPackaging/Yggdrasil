# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SQLCipher"
version = v"4.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sqlcipher/sqlcipher.git", "c5bd336ece77922433aaf6d6fe8cf203b0c299d5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sqlcipher

# use same flags as SQLite_jll
# plus those provided at https://github.com/sqlcipher/sqlcipher
export CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1 \
                 -DSQLITE_ENABLE_UNLOCK_NOTIFY \
                 -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
                 -DSQLITE_ENABLE_FTS3_TOKENIZER=1 \
                 -DSQLITE_SECURE_DELETE \
                 -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
                 -DSQLITE_MAX_EXPR_DEPTH=10000"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-tempstore=yes \
    --disable-static \
    --enable-fts3 \
    --enable-fts4 \
    --enable-fts5 \
    --enable-rtree \
    --enable-json1 \
    CFLAGS="-DSQLITE_HAS_CODEC" \
    LDFLAGS="-L${libdir}" \
    LDFLAGS="-lcrypto"

make -j${nproc}
make install

# SQLCipher and SQLite licenses
install_license LICENSE*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> libc(p) != "musl" && !Sys.isfreebsd(p) && !Sys.iswindows(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsqlcipher", :libsqlcipher),
    ExecutableProduct("sqlcipher", :sqlcipher)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Required for amalgamation, could not build without it
    HostBuildDependency("Tcl_jll"),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
