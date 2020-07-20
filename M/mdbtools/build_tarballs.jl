# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mdbtools"
version = v"0.8.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cyberemissary/mdbtools.git", "b753ff36a0f1d88ae8a300ed6712f4aa2ddb7d08")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mdbtools/
autoreconf -if
apk add glib-dev
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man
make -j8
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf)
    MacOS(:x86_64)
    FreeBSD(:x86_64)
    Windows(:i686)
    Windows(:x86_64)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("mdb-count", :mdb_count),
    ExecutableProduct("mdb-ver", :mbd_ver),
    ExecutableProduct("mdb-prop", :mdb_prop),
    ExecutableProduct("mdb-sql", :mdb_sql),
    ExecutableProduct("mdb-tables", :mdb_tables),
    ExecutableProduct("mdb-schema", :mdb_schema),
    ExecutableProduct("mdb-parsecsv", :mdb_parsecsv),
    ExecutableProduct("mdb-header", :mdb_header),
    ExecutableProduct("mdb-export", :mdb_export),
    ExecutableProduct("mdb-hexdump", :mdb_hexdump),
    LibraryProduct("libmdbsql", :libmdbsql),
    LibraryProduct("libmdb", :libmdb),
    ExecutableProduct("mdb-array", :mdb_array)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
