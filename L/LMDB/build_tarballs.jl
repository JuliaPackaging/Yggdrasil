using BinaryBuilder

name = "LMDB"
version = v"0.9.25"

# No sources, we're just building the testsuite
sources = [
    ArchiveSource("https://git.openldap.org/openldap/openldap/-/archive/LMDB_0.9.25/openldap-LMDB_$(version).tar.gz",
                  "4f6eebe5ad98c10a75badd106f498ee2249d454352d048c78a49c99c940d4cae"),
]

# Bash recipe for building across all platforms
# rm: remove man files (it does not name sense)
# exeext: Makefile does not support extensions - need to rename execuables manually
script = raw"""
cd ${WORKSPACE}/srcdir/openldap-*/libraries/liblmdb
make SOEXT=.${dlext} -j${nproc}
make SOEXT=.${dlext} ILIBS=liblmdb.${dlext} prefix=${prefix} install
rm -rf ${prefix}/share
if [ "${exeext}" ]; then
    for f in ${prefix}/bin/*; do
        mv "${f}" "${f}${exeext}"
    done
fi
install_license ${WORKSPACE}/srcdir/openldap-*/libraries/liblmdb/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("mdb_copy", :mdb_copy),
    ExecutableProduct("mdb_dump", :mdb_dump),
    ExecutableProduct("mdb_load", :mdb_load),
    ExecutableProduct("mdb_stat", :mdb_stat),
    LibraryProduct("liblmdb", :liblmdb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
