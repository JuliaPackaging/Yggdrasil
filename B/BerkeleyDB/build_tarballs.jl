# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BerkeleyDB"
version = v"6.0.19"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.oracle.com/berkeley-db/db-$(version).tar.gz", "2917c28f60903908c2ca4587ded1363b812c4e830a5326aaa77c9879d13ae18e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/db-*/dist
update_configure_scripts
cd ../build_unix
../dist/configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("db_hotbackup", :db_hotbackup),
    ExecutableProduct("db_log_verify", :db_log_verify),
    ExecutableProduct("db_tuner", :db_tuner),
    ExecutableProduct("db_printlog", :db_printlog),
    ExecutableProduct("db_archive", :db_archive),
    ExecutableProduct("db_dump", :db_dump),
    ExecutableProduct("db_load", :db_load),
    ExecutableProduct("db_upgrade", :db_upgrade),
    ExecutableProduct("db_checkpoint", :db_checkpoint),
    ExecutableProduct("db_replicate", :db_replicate),
    ExecutableProduct("db_stat", :db_stat),
    ExecutableProduct("db_recover", :db_recover),
    LibraryProduct("libdb", :libdb),
    ExecutableProduct("db_verify", :db_verify),
    ExecutableProduct("db_deadlock", :db_deadlock)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
