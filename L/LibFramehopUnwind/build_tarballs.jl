# Note that this script can accept some limited command-line arguments, type
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibFramehopUnwind"
version = v"0.1.2"

# Collection of sources required to complete build.
# The crate has no release tags yet, so pin the source to a specific commit.
sources = [
    GitSource("https://github.com/gbaraldi/framehopunwind.git",
              "745330dc336f4237cac36db79b5c9b6bc15c0232"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/framehopunwind

# `crate-type = ["staticlib", "cdylib", "rlib"]` produces both a C-callable
# shared library and a static library. Cargo.lock is committed and the crate
# emphasises reproducible builds, so build with --locked. Frame pointers are
# forced on via the crate's own .cargo/config.toml.
cargo build --release --locked -j${nproc} --target=${rust_target}

RELDIR="target/${rust_target}/release"

# Shared library (cdylib). On Windows the DLL has no "lib" prefix, so rename it
# on install to keep a single library name across platforms.
if [[ "${target}" == *-w64-mingw32* ]]; then
    install -Dvm 0755 "${RELDIR}/framehopunwind.${dlext}" "${libdir}/libframehopunwind.${dlext}"
else
    install -Dvm 0755 "${RELDIR}/libframehopunwind.${dlext}" "${libdir}/libframehopunwind.${dlext}"
fi

# Static library (staticlib) — shipped so downstream can link either flavour.
install -Dvm 0644 "${RELDIR}/libframehopunwind.a" "${prefix}/lib/libframehopunwind.a"

# Public C header.
install -Dvm 0644 include/framehopunwind.h "${includedir}/framehopunwind.h"

install_license LICENSE-MIT LICENSE-APACHE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# framehop only implements x86_64 and aarch64 unwinding.
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)

# framehop's PE (Windows) backend is x86_64-only.
filter!(p -> !(Sys.iswindows(p) && arch(p) != "x86_64"), platforms)

# BinaryBuilder's Rust toolchain can't produce a `cdylib` against musl.
filter!(p -> libc(p) != "musl", platforms)

# aarch64-freebsd is not yet supported by our Rust toolchain.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libframehopunwind", :libframehopunwind),
    FileProduct("lib/libframehopunwind.a", :libframehopunwind_a),
    FileProduct("include/framehopunwind.h", :framehopunwind_h),
]

# Dependencies that must be installed before this package can be built.
# (libgcc_s.so.1, linked in by the Rust toolchain, is always present in a running
# Julia process; the auditor's "could not be auto-mapped" note is benign.)
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
