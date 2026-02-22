# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SQLCipher"
version = v"4.13.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sqlcipher/sqlcipher.git", "222bdcafad462a1080360de1928cd900a8bccd0a")
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
    --with-tempstore=yes \
    --disable-static \
    --enable-fts3 \
    --enable-fts4 \
    --enable-fts5 \
    --enable-rtree \
    # SQLITE_EXTRA_INIT and _SHUTDOWN required since v4.7.0
    CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_EXTRA_INIT=sqlcipher_extra_init -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown" \
    LDFLAGS="-L${libdir} -lcrypto"

make -j${nproc}
make install

# Since v4.7.0, default build outputs are sqlite3/libsqlite3 instead of sqlcipher/libsqlcipher.
# Rename to preserve the existing JLL product names.
cd ${prefix}
mv bin/sqlite3 bin/sqlcipher
for f in lib/libsqlite3.*; do
    mv "$f" "$(echo $f | sed 's/libsqlite3/libsqlcipher/')"
done
# Recreate symlinks
cd lib
ln -sf libsqlcipher.so.*.*.* libsqlcipher.so
ln -sf libsqlcipher.so.*.*.* libsqlcipher.so.0

cd $WORKSPACE/srcdir/sqlcipher
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
