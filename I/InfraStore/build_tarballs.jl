# Yggdrasil build recipe for InfraStore_jll.
#
# This produces the `libinfrastore_ffi` binary that `InfraStore.jl` (and,
# through it, InfrastructureSystems.jl) loads.
#
# HDF5 policy: the build keeps the crate's default `vendored` feature,
# which compiles HDF5 and zlib from source and links them
# statically. That pins the exact HDF5 version backing the on-disk format to
# the one infrastore was tested against, instead of whatever HDF5_jll the
# user's environment resolves -- the store is a data artifact with a format
# contract (DATA_FORMAT_VERSION), not a general HDF5 surface.
#
# The alternative -- linking HDF5_jll -- was built and works (see
# this file's history), but was rejected deliberately:
#
#   * Those JLLs are MPI-augmented and publish no serial variant, so linking
#     them forces an MPI runtime dependency and a 17-triplet build matrix onto
#     a library that never calls MPI, and propagates that dependency to every
#     downstream user.
#   * The usual one-libhdf5-per-process argument does not apply here. The
#     cdylib exports only its own `infrastore_*` C API -- the statically
#     linked HDF5 symbols stay local (verified with nm; Julia
#     additionally dlopens with RTLD_LOCAL|RTLD_DEEPBIND) -- so it cannot
#     collide with HDF5.jl's copy in the same process.
#   * The remaining hazard, two HDF5 instances opening the same file, requires
#     a user to open a live store's .h5 with HDF5.jl/NCDatasets.jl directly.
#     That is explicitly unsupported; the store must be accessed through
#     InfraStore.jl.
#
# ---------------------------------------------------------------------------
# Building locally (no Yggdrasil checkout required -- the recipe has no
# cross-recipe includes):
#
#   julia build_tarballs.jl --verbose --debug x86_64-linux-gnu
#
# Note that a platform argument REPLACES the `platforms` list below rather
# than filtering it, but since the platforms carry no extra tags, bare
# triplets are exactly right. Omit the argument to build the full list.
# ---------------------------------------------------------------------------

using BinaryBuilder, Pkg

name = "InfraStore"
version = v"0.5.1"

# Pin to the commit the release tag points at. Yggdrasil requires a full commit
# SHA here -- a tag name is not accepted -- and the commit must already be
# pushed. Get it with:
#
#   git rev-parse v0.5.1^{commit}
#
# This is v0.5.1 of https://github.com/NatLabRockies/infrastore. Note that only
# changes under crates/, Cargo.toml, or Cargo.lock require a new SHA here;
# edits to this recipe do not, since Yggdrasil builds from its own copy.
sources = [
    GitSource(
        "https://github.com/NatLabRockies/infrastore.git",
        "32f95c8965f2ce4c84ccf9c2c46032fd28bae073",
    ),
    DirectorySource("./bundled"),
]

# Build the FFI cdylib with the default `vendored` feature: HDF5 and
# zlib are compiled from the sources vendored by hdf5-metno-src and
# linked statically, so the artifact is self-contained.
script = raw"""
cd ${WORKSPACE}/srcdir/infrastore

# Source-tree modifications live in bundled/patches.
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# The vendored HDF5 needs cmake >= 3.26 and the build rootfs ships 3.21, so
# CMake_jll is pulled in as a host dependency below. Its bin dir sits on PATH
# behind the rootfs tools; deleting the rootfs cmake lets it win.
apk del cmake

# The vendored HDF5/zlib builds run through the Rust `cmake` crate,
# which honors CMAKE_TOOLCHAIN_FILE from the environment; point it at
# BinaryBuilder's target toolchain so those builds cross-compile.
# hdf5-metno-src pre-seeds the try-run cache variables HDF5's cmake needs when
# cross-compiling.
#
# One value has to be neutralized: BinaryBuilder's toolchain hardcodes
# `set(CMAKE_INSTALL_PREFIX $ENV{prefix})`, which overrides the install prefix
# the cmake crate passes on the command line, so the intermediate HDF5
# installs land in ${prefix} instead of the crate OUT_DIRs and the dependent
# build scripts cannot find them (hdf5-metno-sys: "H5pubconf header not found").
#
# Rather than editing the toolchain, wrap it. The generated file is included
# verbatim, then the *normal* variable it defined is dropped, which re-exposes
# the cache entry the cmake crate set with -DCMAKE_INSTALL_PREFIX (a normal
# variable shadows a cache variable of the same name). Nothing is pattern-
# matched, so this cannot drift if the toolchain's formatting changes, and
# anything the toolchain itself computed from the prefix during the include is
# preserved -- which deleting the line would have discarded.
cat > "${WORKSPACE}/srcdir/target_toolchain.cmake" <<EOF
include("${CMAKE_TARGET_TOOLCHAIN}")
unset(CMAKE_INSTALL_PREFIX)
EOF
export CMAKE_TOOLCHAIN_FILE="${WORKSPACE}/srcdir/target_toolchain.cmake"

# HDF5's H5system.c calls StrStrIA (shlwapi). Its cmake links shlwapi only for
# MSVC, so the mingw link of the cdylib must add it explicitly or the final
# link fails with: undefined reference to `__imp_StrStrIA`.
if [[ "${target}" == *-mingw* ]]; then
    export RUSTFLAGS="-C link-arg=-lshlwapi"
fi

# HDF5_DIR must remain UNSET in this environment: hdf5-metno-sys only takes
# its build-from-source path when the `static` feature is enabled AND HDF5_DIR
# is absent. Setting it would flip the build to external-library discovery,
# including a dlopen() runtime-version probe that cannot work when
# cross-compiling.

cargo build --release --target ${rust_target} -p infrastore-ffi

# Rust does not prefix cdylibs with `lib` on Windows: the artifact there is
# `infrastore_ffi.dll` (next to a `libinfrastore_ffi.dll.a` import library),
# while Linux and macOS produce `libinfrastore_ffi.{so,dylib}`. Glob over the
# prefix and install under the `lib`-prefixed name on every platform, so the
# LibraryProduct declared below resolves identically everywhere.
#
# `${libdir}` already resolves to `${prefix}/bin` on Windows, which is where
# BinaryBuilder expects DLLs, so the destination needs no special-casing.
install -Dvm755 target/${rust_target}/release/*infrastore_ffi.${dlext} \
    "${libdir}/libinfrastore_ffi.${dlext}"
install -Dvm644 "crates/infrastore-ffi/include/infrastore.h" \
    "${includedir}/infrastore.h"
"""

# This is a test to see what fails. A follow-on commit will remove failing
# builds with reasons.
# With no JLL binary dependencies there are no artifact-matching tags toolchain
# mirror -- plain triplets are sufficient.
platforms = supported_platforms()

# 32-bit targets are dropped: the on-disk format indexes arrays with 64-bit
# offsets and lengths throughout, and the HDF5 stack has never been
# built or exercised against a 32-bit target here.
filter!(p -> nbits(p) == 64, platforms)

products = [
    LibraryProduct("libinfrastore_ffi", :libinfrastore_ffi),
]

# Self-contained by design: HDF5 and zlib are statically linked, so
# there are no runtime binary dependencies. See the header comment before
# adding any. CMake_jll is host-only: the vendored HDF5 requires CMake >= 3.26
# and the build rootfs ships 3.21, so pull a current cmake onto the PATH (the
# Rust `cmake` crate invokes whatever `cmake` PATH resolves to).
dependencies = [
    HostBuildDependency(PackageSpec(name = "CMake_jll", version = "3.31.9")),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers = [:c, :rust],
    julia_compat = "1.10",
    # Must be >= the workspace's `rust-version`, and the workspace is on edition
    # 2024 (Rust >= 1.85). BinaryBuilder otherwise defaults to whatever its
    # newest Rust shard happens to be, which makes the toolchain drift silently.
    #
    # This is a tight constraint worth watching: 1.94.0 is currently BOTH the
    # workspace MSRV and the newest shard BinaryBuilderBase ships. Raising
    # `rust-version` in the root Cargo.toml above 1.94 makes this JLL
    # unbuildable until Yggdrasil publishes a matching RustBase artifact, so
    # check the available versions before bumping the MSRV:
    #
    #   https://github.com/JuliaPackaging/BinaryBuilderBase.jl/blob/master/Artifacts.toml
    preferred_rust_version = v"1.94.0",
)
