# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DuckDB"
version = v"0.9.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/duckdb/duckdb.git", "3c695d7ba94d95d9facee48d395f46ed0bd72b46"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/duckdb/

mkdir build && cd build

if [[ "${target}" == *86*-linux-gnu ]]; then
    export LDFLAGS="-lrt";
elif [[ "${target}" == *-mingw* ]]; then
    # `ResolveLocaleName` requires Windows 7: https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-resolvelocalename
    export CXXFLAGS="-DWINVER=_WIN32_WINNT_WIN7 -D_WIN32_WINNT=_WIN32_WINNT_WIN7"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_PARQUET_EXTENSION=TRUE \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_SANITIZER=FALSE \
      -DBUILD_ICU_EXTENSION=TRUE \
      -DBUILD_JSON_EXTENSION=TRUE \
      -DBUILD_UNITTESTS=FALSE ..
make -j${nproc}
make install

if [[ "${target}" == *-mingw32 ]]; then
    install -Dvm 755 "src/libduckdb.${dlext}" "${libdir}/libduckdb.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0", julia_compat="1.6")
