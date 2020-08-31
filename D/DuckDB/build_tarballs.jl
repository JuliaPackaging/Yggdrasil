# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DuckDB"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cwida/duckdb.git", "d9bceddc7209a7e0b5c0402958d1191e19a491e7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd duckdb/
if [[ "${target}" == *-mingw32 ]]; then
    sed -i -E "/add_executable\(duckdb_rest_server server.cpp\)$/aif\(\$\{WIN32\}\)\n  set\(LINK_EXTRA -lwsock32 -lws2_32\)\nendif\(\)\n" tools/rest/CMakeLists.txt
fi

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DDISABLE_UNITY=TRUE -DENABLE_SANITIZER=FALSE -DBUILD_UNITTESTS=FALSE ..
make -j${nproc}
make install


if [[ "${target}" == *-mingw32 ]]; then
    mkdir -p ${libdir}
    cp src/libduckdb.${dlext} ${libdir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64)
]
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
