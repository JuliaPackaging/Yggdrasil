# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SQLite"
# NOTE: This version has been yanked (disabled) in the Julia registry.
#
# SQLite 3.49.0 uses a new build system (autosetup instead of
# autoconf), and this leads to different names for all shared
# libraries, in particular on Windows. This makes this version
# incompatible with earlier versions.
#
# We will either need to rename the shared libraries (if possible) or
# increase the major version number of this package.
version = v"3.49.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sqlite.org/2025/sqlite-autoconf-3490000.tar.gz",
                  "4d8bfa0b55e36951f6e5a9fb8c99f3b58990ab785c57b4f84f37d163a0672759"),
    FileSource("https://raw.githubusercontent.com/archlinux/svntogit-community/cf0a3337bd854104252dc1ff711e95cc8bc7ffb3/trunk/license.txt",
               "4e57d9ac979f1c9872e69799c2597eeef4c6ce7224f3ede0bf9dc8d217b1e65d";
               filename="LICENSE"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sqlite-autoconf-*

# Use same flags as
# https://github.com/archlinux/svntogit-packages/blob/packages/sqlite/trunk/PKGBUILD
export CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1 \
                 -DSQLITE_ENABLE_UNLOCK_NOTIFY \
                 -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
                 -DSQLITE_ENABLE_FTS3_TOKENIZER=1 \
                 -DSQLITE_ENABLE_FTS3_PARENTHESIS \
                 -DSQLITE_SECURE_DELETE \
                 -DSQLITE_ENABLE_STMTVTAB \
                 -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
                 -DSQLITE_MAX_EXPR_DEPTH=10000 \
                 -DSQLITE_ENABLE_MATH_FUNCTIONS \
                 -DSQLITE_USE_URI"

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=$target \
    --disable-static \
    --enable-fts3 \
    --enable-fts4 \
    --enable-fts5 \
    --enable-rtree
make -j${nproc}
make install
install_license "${WORKSPACE}/srcdir/LICENSE"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsqlite3", :libsqlite),
    ExecutableProduct("sqlite3", :sqlite3),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("dlfcn_win32_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
