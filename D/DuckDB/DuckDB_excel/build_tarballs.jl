# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# Loadable `excel` extension for DuckDB_jll. Shared settings (version, source,
# toolchain, platform mapping) live in ../common.jl. To ensure a rebuild it
# isn't sufficient to modify common.jl; you also need to update a line in this
# file:
#     Last updated: 2026-09-02
include("../common.jl")

name = "DuckDB_excel"
version = duckdb_version

# The commit duckdb v1.5.5 pins in .github/config/extensions/excel.cmake
excel_commit = "f4c72b5ef04a03b3a78a95b5a2ee94ba93e3178d"

# Collection of sources required to complete build
sources = [
    duckdb_source(),
    GitSource("https://github.com/duckdb/duckdb-excel.git", excel_commit),
    # minizip-ng 4.0.7, the version duckdb-excel's vcpkg manifest pins
    GitSource("https://github.com/zlib-ng/minizip-ng.git", "fe5fedc365f7824ada0cf9a84fb79b30d5fc97a8"),
]

# Bash recipe for building across all platforms
script = duckdb_script_prologue * "EXCEL_COMMIT=$(excel_commit)\n" * raw"""
# Static minizip-ng for the excel extension (there is no minizip-ng JLL); it is
# absorbed into the extension, so nothing from it ships in the tarball.
cmake -S $WORKSPACE/srcdir/minizip-ng -B $WORKSPACE/srcdir/minizip-build \
      -DCMAKE_INSTALL_PREFIX=$WORKSPACE/deps \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DMZ_LIB_SUFFIX=-ng \
      -DMZ_FETCH_LIBS=OFF \
      -DMZ_ZLIB=ON \
      -DZLIB_ROOT=${prefix} \
      -DMZ_BZIP2=OFF \
      -DMZ_LZMA=OFF \
      -DMZ_ZSTD=OFF \
      -DMZ_OPENSSL=OFF \
      -DMZ_LIBBSD=OFF \
      -DMZ_ICONV=OFF \
      -DMZ_PKCRYPT=OFF \
      -DMZ_WZAES=OFF \
      -DMZ_LIBCOMP=OFF \
      -DMZ_BUILD_TESTS=OFF
# minizip-ng silently disables deflate when it fails to find zlib, which breaks
# every read_xlsx/write at runtime — fail the build instead
if grep -rq "MZ_ZIP_NO_COMPRESSION" $WORKSPACE/srcdir/minizip-build/CMakeFiles/*.dir/flags.make; then
    echo "ERROR: minizip-ng configured without zlib (no compression support)" >&2
    exit 1
fi
cmake --build $WORKSPACE/srcdir/minizip-build --parallel ${nproc}
cmake --install $WORKSPACE/srcdir/minizip-build

# Out-of-tree extension config. The stock .github/config/extensions/excel.cmake
# would git-clone at configure time; this loads the pre-fetched source instead.
# DONT_LINK: build the loadable `excel.duckdb_extension` only, do not link the
# extension into libduckdb (which this recipe does not ship anyway).
cat > $WORKSPACE/srcdir/extension_config.cmake <<EOC
duckdb_extension_load(excel
    DONT_LINK
    SOURCE_DIR $WORKSPACE/srcdir/duckdb-excel
    INCLUDE_DIR $WORKSPACE/srcdir/duckdb-excel/src/excel/include
    EXTENSION_VERSION ${EXCEL_COMMIT:0:7}
)
EOC

cd $WORKSPACE/srcdir/duckdb/

cmake -B build "${DUCKDB_CMAKE_ARGS[@]}" \
      -DCMAKE_PREFIX_PATH=$WORKSPACE/deps \
      -DCMAKE_CXX_FLAGS="-I$WORKSPACE/deps/include" \
      -DBUILD_SHELL=FALSE \
      -DDUCKDB_EXTENSION_CONFIGS=$WORKSPACE/srcdir/extension_config.cmake
# Only the loadable extension (and the static DuckDB it links) is needed.
cmake --build build --parallel ${nproc} --target excel_loadable_extension

ext_file=$(find build/extension/excel -name 'excel.duckdb_extension' | head -n1)
if [[ -z "${ext_file}" ]]; then
    echo "ERROR: excel.duckdb_extension was not produced" >&2
    exit 1
fi
# DuckDB appends a metadata footer (platform, version, signature slot) to the
# binary; without it libduckdb refuses to load the file.
if ! tail -c 512 "${ext_file}" | grep -q -- "${DUCKDB_TARGET}"; then
    echo "ERROR: ${ext_file} lacks the DuckDB metadata footer for ${DUCKDB_TARGET}" >&2
    exit 1
fi

# Layout expected by DuckDB's `extension_directory`/`extension_directories`
# settings: <dir>/<version>/<platform>/<name>.duckdb_extension
install -Dvm 755 "${ext_file}" \
    "${prefix}/duckdb_extensions/${DUCKDB_VERSION_TAG}/${DUCKDB_TARGET}/excel.duckdb_extension"

install_license $WORKSPACE/srcdir/duckdb-excel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = duckdb_platforms()

# The products that we will ensure are always built. DuckDB.jl points the
# `extension_directories` setting at this directory; DuckDB itself appends the
# version and platform components.
products = [
    FileProduct("duckdb_extensions", :duckdb_extensions_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # The extension's footer must match libduckdb's version exactly, so pin it.
    RuntimeDependency("DuckDB_jll"; compat="=$(duckdb_version)"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Zlib_jll"),
]

sources, script = duckdb_macos_sdk(sources, script)

# Build the tarballs, and possibly a `build.jl` as well.
# skip_audit: the audit would run patchelf/install_name_tool over the
# `.duckdb_extension` shared object to adjust rpaths, which rewrites the file
# and can destroy the metadata footer appended after the last section. The
# extension needs no rpath: its dependencies (libexpat, libz) are already
# loaded into the process by their JLLs when libduckdb dlopens it.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               skip_audit=true, duckdb_build_kwargs...)
