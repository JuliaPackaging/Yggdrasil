# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# Shared settings (version, source, toolchain, platform mapping) live in
# ../common.jl. To ensure a rebuild it isn't sufficient to modify common.jl;
# you also need to update a line in this file:
#     Last updated: 2026-09-02
include("../common.jl")

name = "DuckDB"
version = duckdb_version

# Collection of sources required to complete build
sources = [
    duckdb_source(),
]

# Bash recipe for building across all platforms
script = duckdb_script_prologue * raw"""
cd $WORKSPACE/srcdir/duckdb/

# The statically linked extensions match upstream's own release binaries
# (.github/config/bundled_extensions.cmake). Everything else is meant to be
# provided as a loadable extension by a DuckDB_<ext>_jll built from ../common.jl.
cmake -B build "${DUCKDB_CMAKE_ARGS[@]}" \
      -DBUILD_EXTENSIONS='parquet;json;icu;autocomplete' \
      -DBUILD_SHELL=TRUE
cmake --build build --parallel ${nproc}
cmake --install build

if [[ "${target}" == *-mingw32 ]]; then
    install -Dvm 755 "build/src/libduckdb.${dlext}" -t "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = duckdb_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb),
    ExecutableProduct("duckdb", :duckdb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

sources, script = duckdb_macos_sdk(sources, script)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; duckdb_build_kwargs...)
