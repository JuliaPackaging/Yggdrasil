# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DuckDB"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/duckdb/duckdb.git", "b390a7c3760bd95926fe8aefde20d04b349b472e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/duckdb/

export DUCKDB_TARGET="${target}"
if [[ "${target}" == "x86_64-linux-gnu" ]]; then
    export DUCKDB_TARGET="linux_amd64"
elif [[ "${target}" == aarch64-linux-gnu ]]; then
    export DUCKDB_TARGET="linux_arm64"
elif [[ "${target}" == "x86_64-linux-musl" ]]; then
    export DUCKDB_TARGET="linux_amd64_musl"
elif [[ "${target}" == "x86_64-w64-mingw32" ]]; then
    export DUCKDB_TARGET="windows_amd64_mingw"
elif [[ "${target}" == x86_64-apple-* ]]; then
    export DUCKDB_TARGET="osx_amd64"
elif [[ "${target}" == aarch64-apple-* ]]; then
    export DUCKDB_TARGET="osx_arm64"
fi

if [[ "${bb_full_target}" == *-cxx03* ]]; then
    export DUCKDB_TARGET="${DUCKDB_TARGET}_gcc4"
fi

echo "Compiling for DuckDB Target - $DUCKDB_TARGET"

cmake -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_SANITIZER=FALSE \
      -DBUILD_EXTENSIONS='parquet;json' \
      -DSKIP_EXTENSIONS=jemalloc \
      -DENABLE_EXTENSION_AUTOLOADING=1 \
      -DENABLE_EXTENSION_AUTOINSTALL=1 \
      -DBUILD_UNITTESTS=FALSE \
      -DBUILD_SHELL=TRUE \
      -DDUCKDB_EXPLICIT_PLATFORM=${DUCKDB_TARGET}
cmake --build build --parallel ${nproc}
cmake --install build

if [[ "${target}" == *-mingw32 ]]; then
    install -Dvm 755 "build/src/libduckdb.${dlext}" -t "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# Building for PowerPC results in errors inside jemalloc:
#     /tmp/ccmHnfhC.s: Assembler messages:
#     /tmp/ccmHnfhC.s:7829: Error: unrecognized opcode: `pause'
#     make[2]: *** [extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/build.make:76: extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/src/jemalloc.c.o] Error 1
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb),
    ExecutableProduct("duckdb", :duckdb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0", julia_compat="1.6")
