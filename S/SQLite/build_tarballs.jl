# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SQLite"
version = v"3.31.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sqlite.org/2020/sqlite-autoconf-3320300.tar.gz", "a31507123c1c2e3a210afec19525fd7b5bb1e19a6a34ae5b998fbd7302568b66"),
    ArchiveSource("https://git.archlinux.org/svntogit/packages.git/plain/trunk/license.txt?h=packages/sqlite&id=33cad63ddb1ba86b7c5a47430c98083ce2b4d86b",
                  "4e57d9ac979f1c9872e69799c2597eeef4c6ce7224f3ede0bf9dc8d217b1e65d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sqlite-autoconf-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
# Manually install the license with a super funky name
mkdir -p "${prefix}/share/licenses/${SRC_NAME}"
cp $WORKSPACE/srcdir/*id=* "${prefix}/share/licenses/${SRC_NAME}/LICENSE"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsqlite3", :libsqlite)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
