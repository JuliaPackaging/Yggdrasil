# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DuckDB"
version = v"0.2.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/duckdb/duckdb/archive/refs/tags/v0.2.9.tar.gz", "ede74256ca8811ae37001d238c4ffb156861c408453e95e02096773465619ccf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd duckdb-0.2.9/
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
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0")
