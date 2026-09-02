# Shared definitions for the DuckDB family of JLLs:
#
#   D/DuckDB/DuckDB        -> DuckDB_jll        libduckdb + the duckdb shell
#   D/DuckDB/DuckDB_<ext>  -> DuckDB_<ext>_jll  one loadable DuckDB extension each
#
# libduckdb only loads a `.duckdb_extension` file whose metadata footer carries
# exactly its own version and platform string, and the extension only works if
# it was compiled with the same toolchain (GCC version, C++ string ABI, macOS
# SDK). Everything that feeds into those lives in this file so that all recipes
# move in lockstep. When bumping DuckDB: change this file, then touch the
# "Last updated" line in every consumer so Yggdrasil's CI rebuilds them all.
using BinaryBuilder, Pkg

include("../../platforms/macos_sdks.jl")

const duckdb_version = v"1.5.5"
const duckdb_commit = "d8cdaa33fda8df955cc76ef58a280f68f4cd43fa"

duckdb_source() = GitSource("https://github.com/duckdb/duckdb.git", duckdb_commit)

# Keyword arguments every DuckDB recipe passes to `build_tarballs`.
# GCC 10 (not older): the autocomplete extension needs a newer libstdc++ than
# GCC 6.1's, and upstream builds its mingw binaries with GCC 10 as well.
const duckdb_build_kwargs = (; preferred_gcc_version = v"10.2.0", julia_compat = "1.6")

function duckdb_platforms()
    platforms = expand_cxxstring_abis(supported_platforms())
    # Building for PowerPC results in errors inside jemalloc:
    #     /tmp/ccmHnfhC.s: Assembler messages:
    #     /tmp/ccmHnfhC.s:7829: Error: unrecognized opcode: `pause'
    #     make[2]: *** [extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/build.make:76: extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/src/jemalloc.c.o] Error 1
    filter!(p -> arch(p) != "powerpc64le", platforms)
    return platforms
end

# The default macOS 10.12 SDK (and even 10.15) has a libc++ that doesn't provide
# std::hash for enum types (LWG 2148). Use SDK 14.0 which definitely includes it.
# DuckDB itself targets macOS 11.0, so we set that as the deployment target.
duckdb_macos_sdk(sources, script) = require_macos_sdk("14.0", sources, script; deployment_target="11.0")

# Shell prologue shared by all recipes. It exports
#   DUCKDB_TARGET       DuckDB's platform string for this target (also the name of
#                       the per-platform directory extensions are looked up in)
#   DUCKDB_VERSION_TAG  the version directory name, e.g. `v1.5.5`
# and defines the bash array DUCKDB_CMAKE_ARGS with the cmake options that must be
# identical between libduckdb and every extension built against it.
const duckdb_script_prologue = """
export DUCKDB_VERSION_TAG="v$(duckdb_version)"
# Pin what `git describe` would report so the version baked into libduckdb and
# into extension footers is exactly the release tag, independent of how the
# source checkout looks.
export DUCKDB_GIT_DESCRIBE="v$(duckdb_version)-0-g$(duckdb_commit[1:9])"
""" * raw"""
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

DUCKDB_CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DENABLE_SANITIZER=FALSE
    -DENABLE_JEMALLOC=OFF
    -DENABLE_EXTENSION_AUTOLOADING=1
    -DENABLE_EXTENSION_AUTOINSTALL=1
    # Loadable extensions embed the DuckDB code they use and export only their
    # init symbol, so they do not depend on how Julia dlopened libduckdb. This
    # is how upstream distributes extensions too.
    -DEXTENSION_STATIC_BUILD=ON
    -DBUILD_UNITTESTS=FALSE
    -DDUCKDB_EXPLICIT_PLATFORM=${DUCKDB_TARGET}
    -DOVERRIDE_GIT_DESCRIBE=${DUCKDB_GIT_DESCRIBE}
)
"""
