# Yggdrasil build recipe for InfraStore_jll.
#
# This produces the `libinfrastore_ffi` binary that `InfraStore.jl` (and,
# through it, InfrastructureSystems.jl) loads.
#
# HDF5/NetCDF policy: the build keeps the crate's default `vendored` feature,
# which compiles netcdf-c, HDF5, and zlib from source and links them
# statically. That pins the exact HDF5 version backing the on-disk format to
# the one infrastore was tested against, instead of whatever HDF5_jll the
# user's environment resolves -- the store is a data artifact with a format
# contract (DATA_FORMAT_VERSION), not a general HDF5 surface.
#
# The alternative -- linking NetCDF_jll/HDF5_jll -- was built and works (see
# this file's history), but was rejected deliberately:
#
#   * Those JLLs are MPI-augmented and publish no serial variant, so linking
#     them forces an MPI runtime dependency and a 17-triplet build matrix onto
#     a library that never calls MPI, and propagates that dependency to every
#     downstream user.
#   * The usual one-libhdf5-per-process argument does not apply here. The
#     cdylib exports only its own `infrastore_*` C API -- the statically
#     linked HDF5/netcdf symbols stay local (verified with nm; Julia
#     additionally dlopens with RTLD_LOCAL|RTLD_DEEPBIND) -- so it cannot
#     collide with HDF5.jl's copy in the same process.
#   * The remaining hazard, two HDF5 instances opening the same file, requires
#     a user to open a live store's .nc with HDF5.jl/NCDatasets.jl directly.
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
version = v"0.2.1"

# Pin to the commit the release tag points at. Yggdrasil requires a full commit
# SHA here -- a tag name is not accepted -- and the commit must already be
# pushed. Get it with:
#
#   git rev-parse v0.1.0^{commit}
#
# This is v0.1.0 of https://github.com/NatLabRockies/infrastore. Note that only
# changes under crates/, Cargo.toml, or Cargo.lock require a new SHA here;
# edits to this recipe do not, since Yggdrasil builds from its own copy.
sources = [
    GitSource(
        "https://github.com/NatLabRockies/infrastore.git",
        "baeb72d9b63915ad9ccaa307cc1632162458d90d",
    ),
]

# Build the FFI cdylib with the default `vendored` feature: netcdf-c, HDF5, and
# zlib are compiled from the sources vendored by netcdf-src/hdf5-metno-src and
# linked statically, so the artifact is self-contained.
script = raw"""
cd ${WORKSPACE}/srcdir/infrastore

# The vendored HDF5 needs cmake >= 3.26 and the build rootfs ships 3.21, so
# CMake_jll is pulled in as a host dependency below. Its bin dir sits on PATH
# behind the rootfs tools; deleting the rootfs cmake lets it win.
apk del cmake

# The vendored netcdf-c/HDF5/zlib builds run through the Rust `cmake` crate,
# which honors CMAKE_TOOLCHAIN_FILE from the environment; point it at
# BinaryBuilder's target toolchain so those builds cross-compile.
# hdf5-metno-src pre-seeds the try-run cache variables HDF5's cmake needs when
# cross-compiling.
#
# One line must be stripped: BinaryBuilder's toolchain hardcodes
# `set(CMAKE_INSTALL_PREFIX $ENV{prefix})`, which overrides the install prefix
# the cmake crate passes on the command line, so the intermediate HDF5/netcdf
# installs land in ${prefix} instead of the crate OUT_DIRs and the dependent
# build scripts cannot find them (hdf5-metno-sys: "H5pubconf header not found").
sed '/set(CMAKE_INSTALL_PREFIX/d' "${CMAKE_TARGET_TOOLCHAIN}" > /tmp/target_toolchain.cmake
export CMAKE_TOOLCHAIN_FILE=/tmp/target_toolchain.cmake

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

# BinaryBuilder forbids forcing an arch via -march, so sha2's ARMv8-crypto `asm`
# kernels cannot be assembled here; use the portable SHA-256 (x86_64 still detects
# SHA-NI at runtime) for the distributed binary.
sed -i 's/sha2 = { workspace = true, features = \["asm"\] }/sha2 = { workspace = true }/' \
    crates/infrastore-core/Cargo.toml

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

# The tier-1 targets that cover essentially every InfrastructureSystems.jl user,
# deliberately narrower than `supported_platforms()`. Every platform listed must
# build for the Yggdrasil PR to merge, so start small and widen once these are
# green. With no JLL binary dependencies there are no artifact-matching tags to
# mirror -- plain triplets are sufficient.
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct("libinfrastore_ffi", :libinfrastore_ffi),
]

# Self-contained by design: NetCDF, HDF5, and zlib are statically linked, so
# there are no runtime binary dependencies. See the header comment before
# adding any. CMake_jll is host-only: the vendored HDF5 requires CMake >= 3.26
# and the build rootfs ships 3.21, so pull a current cmake onto the PATH (the
# Rust `cmake` crate invokes whatever `cmake` PATH resolves to).
dependencies = [
    HostBuildDependency(PackageSpec(name = "CMake_jll", uuid = "3f4e10e2-61f2-5801-8945-23b9d642d0e6")),
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
