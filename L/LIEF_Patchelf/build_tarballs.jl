# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LIEF_Patchelf"
version = v"1.0.0"

# 1.0.0 is the newest release carrying tools/lief-patchelf.
commit = "d05b3499b6934137e917c009a4df0a9dc8cb11c5"

sources = [
    GitSource("https://github.com/lief-project/LIEF.git", commit),
    DirectorySource("./bundled"),
]

# A detached checkout has no tag to describe, so stamp the version by hand.
script = """
export LIEF_VERSION_ENV=$(version)
export LIEF_COMMIT=$(commit)
export LIEF_BRANCH=main
""" * raw"""
# LIEF requires CMake >= 3.24; the build environment ships 3.21.
apk del cmake

cd ${WORKSPACE}/srcdir/LIEF
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-undef-major-minor.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-drop-tls-backend.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0003-static-runtime-link-args.patch

export TMPDIR=${WORKSPACE}/tmp
mkdir -p ${TMPDIR}

lief_install=${WORKSPACE}/lief-install
bridge_dir=${WORKSPACE}/cxx-bridge
precompiled=${WORKSPACE}/lief-rs

# lief-ffi's build script only ever locates a prebuilt LIEF, never builds
# one, so produce libLIEF.a and liblief-sys.a here and hand them to cargo.

# LIEF_RUST_API installs the LIEF/rust headers the cxx bridge includes.
# ASM, DEBUG_INFO, OBJC and DYLD_SHARED_CACHE are inverted: ON drops the
# stub implementations the FFI needs and requires LIEF Extended.
# The FFI is not feature-gated, so PE, COFF and MachO are all mandatory.
cmake -GNinja -S . -B build-lief \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_SHARED_LIBS=OFF \
    -DLIEF_RUST_API=ON \
    -DLIEF_INSTALL=ON \
    -DLIEF_ELF=ON -DLIEF_PE=ON -DLIEF_COFF=ON -DLIEF_MACHO=ON \
    -DLIEF_DEX=OFF -DLIEF_ART=OFF \
    -DLIEF_ASM=OFF -DLIEF_DEBUG_INFO=OFF -DLIEF_OBJC=OFF \
    -DLIEF_DYLD_SHARED_CACHE=OFF \
    -DLIEF_RUNTIME=OFF \
    -DLIEF_PRECOMPILED=OFF \
    -DLIEF_C_API=OFF \
    -DLIEF_EXAMPLES=OFF \
    -DLIEF_TESTS=OFF \
    -DLIEF_PYTHON_API=OFF \
    -DLIEF_USE_CCACHE=OFF \
    -DLIEF_USE_MELKOR=OFF
cmake --build build-lief --parallel ${nproc}

# The toolchain file assigns CMAKE_INSTALL_PREFIX with a plain set(), which
# shadows -D, so pass --prefix or all of LIEF lands in the tarball.
cmake --install build-lief --prefix ${lief_install}

# cargo generates only the Rust half of each cxx bridge. The C++ half comes
# from lief-ffigen, a host tool, which is why CARGO_BUILD_TARGET is unset.
env -u CARGO_BUILD_TARGET -u rust_target ${MACHTYPE}-cargo build --release \
    --manifest-path api/rust/crates/Cargo.toml -p lief-ffigen
api/rust/crates/target/release/lief-ffigen \
    --output-dir ${bridge_dir} --source-dir api/rust/crates/lief-ffi

# cmake-ffi installs liblief-sys.a and libLIEF.a side by side, which is the
# lib/ layout LIEF_RUST_PRECOMPILED expects.
cmake -GNinja -S api/rust/cmake-ffi -B build-ffi \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DLIEF_DIR=${lief_install}/lib/cmake/LIEF \
    -DCMAKE_PREFIX_PATH=${lief_install} \
    -DLIEF_RUST_FFI_SRC=${bridge_dir} \
    -DINSTALL_LIEF_CORE=ON
cmake --build build-ffi --parallel ${nproc}
cmake --install build-ffi --prefix ${precompiled}

# Without these, cargo would quietly resolve -lLIEF from ${libdir} instead.
test -f ${precompiled}/lib/libLIEF.a
test -f ${precompiled}/lib/liblief-sys.a

export LIEF_RUST_PRECOMPILED=${precompiled}

# Both archives are static, so LIEF and its vendored dependencies are always
# absorbed into the binary; what is left is the system runtime. Patch 0003
# adds a build.rs that emits the linker arguments for that; the CRT itself is
# a codegen choice, so it has to come from RUSTFLAGS.
case "${target}" in
    *-apple-darwin*)
        # Apple ships no static libSystem, and libc++ is an OS component with
        # a stable ABI, so darwin links both dynamically and needs no flags.
        ;;
    *-mingw*)
        # link-cplusplus emits a bare -lstdc++ that -static-libstdc++ cannot
        # override, so silence cc's detection; build.rs links it by path.
        export CXXSTDLIB=""
        export RUSTFLAGS="${RUSTFLAGS} -C target-feature=+crt-static"
        ;;
    *)
        # Linux and FreeBSD. Under the default PIC model, +crt-static emits
        # -static-pie and wants an rcrt1.o the sysroot lacks; a non-PIE link
        # uses the ordinary crt1.o instead.
        export RUSTFLAGS="${RUSTFLAGS} -C target-feature=+crt-static -C relocation-model=static"
        ;;
esac

# No --locked: patch 0002 prunes rustls, so the lockfile must be updated.
cargo build --release --manifest-path tools/Cargo.toml -p lief-patchelf

install -Dvm 755 "tools/target/${rust_target}/release/lief-patchelf${exeext}" \
                 "${bindir}/lief-patchelf${exeext}"
install_license LICENSE
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("lief-patchelf", :lief_patchelf),
]

# Nothing is linked at runtime; LIEF just needs a newer CMake to build.
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version=v"3.31.9+0")),
]

# GCC 14: LIEF's runtime objects need C++23 even with LIEF_RUNTIME=OFF.
# lock_microarchitecture=false: cargo and the cc crate inject -march flags.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust],
               preferred_gcc_version=v"14.2.0",
               lock_microarchitecture=false)
