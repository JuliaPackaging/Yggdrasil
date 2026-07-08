using BinaryBuilder

name = "LMDB"
version = v"1.0.0"

sources = [
    GitSource("https://git.openldap.org/openldap/openldap.git",
              "2562c3297402d82bbc049c7e645515edb4079eba"),  # LMDB_1.0.0
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# - CC: mdb_env_close0 segfaults on MacOS because CC is set to gcc in Makefile
# - rm: remove man files (it does not make sense)
# - exeext: Makefile does not support extensions - need to rename executables manually
script = raw"""
cd ${WORKSPACE}/srcdir/openldap
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix-lmdb-1.0-platform-builds.patch
cd libraries/liblmdb

make_args=(CC=${CC} SOEXT=.${dlext})
if [[ "${target}" == *-apple-* ]]; then
    make_args+=(LDL= VERSION_OPT="-Wl,-install_name,@rpath/liblmdb.${dlext} -Wl,-current_version,1.0")
elif [[ "${target}" == *-mingw* ]]; then
    make_args+=(LDL= VERSION_OPT=)
elif [[ "${target}" == *-freebsd* ]]; then
    make_args+=(LDL=)
fi

make "${make_args[@]}" -j${nproc}
make "${make_args[@]}" ILIBS=liblmdb.${dlext} prefix=${prefix} install
if [[ "${target}" == *-mingw* ]]; then
    rm -f "${libdir}/liblmdb.${dlext}" "${libdir}/liblmdb.${dlext}.1"
    cp "liblmdb.${dlext}.1.0" "${libdir}/liblmdb.${dlext}"
    rm -f "${libdir}/liblmdb.${dlext}.1.0"
    rm -f "${prefix}/lib/liblmdb.${dlext}" "${prefix}/lib/liblmdb.${dlext}.1" "${prefix}/lib/liblmdb.${dlext}.1.0"
fi
rm -rf ${prefix}/share
if [ -n "${exeext}" ]; then
    for f in ${bindir}/mdb_*; do
        mv "${f}" "${f}${exeext}"
    done
fi
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("mdb_copy", :mdb_copy),
    ExecutableProduct("mdb_drop", :mdb_drop),
    ExecutableProduct("mdb_dump", :mdb_dump),
    ExecutableProduct("mdb_load", :mdb_load),
    ExecutableProduct("mdb_stat", :mdb_stat),
    LibraryProduct("liblmdb", :liblmdb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
