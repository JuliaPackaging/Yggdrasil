# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BerkeleyDB"
version_string = "18.1.40"
version = v"18.1.41" # We need to change version number to build for "experimental" platforms

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.oracle.com/berkeley-db/db-$(version_string).tar.gz",
                  "0cecb2ef0c67b166de93732769abdeba0555086d51de1090df325e18ee8da9c8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/db-*/docs
# see https://stackoverflow.com/questions/64707079/berkeley-db-make-install-fails-on-linux 
mkdir bdb-sql
mkdir gsg_db_server
cd ../dist

# update configure for powerpc
if [[ "${target}" == powerpc64le-* ]]; then
    sed -i s/elf64ppc/elf64lppc/ configure
fi

cd ../build_unix
../dist/configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("db_dump", :db_dump),
    LibraryProduct("libdb", :libdb),
    ExecutableProduct("db_load", :db_load),
    ExecutableProduct("db_stat", :db_stat),
    ExecutableProduct("db_log_verify", :db_log_verify),
    ExecutableProduct("db_archive", :db_archive),
    ExecutableProduct("db_deadlock", :db_deadlock),
    ExecutableProduct("db_hotbackup", :db_hotbackup),
    ExecutableProduct("db_tuner", :db_tuner),
    ExecutableProduct("db_checkpoint", :db_checkpoint),
    ExecutableProduct("db_recover", :db_recover),
    ExecutableProduct("db_replicate", :db_replicate),
    ExecutableProduct("db_printlog", :db_printlog),
    ExecutableProduct("db_verify", :db_verify),
    ExecutableProduct("db_upgrade", :db_upgrade),
    ExecutableProduct("db_convert", :db_convert)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
