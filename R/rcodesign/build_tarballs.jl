# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "rcodesign"
# apple-codesign 0.29.0 plus patches maintained at JuliaCI/apple-platform-rs
# (two Mach-O robustness fixes and a feature-gated `aws-kms` remote-signing
# backend, all submitted upstream). The crate version is unchanged; the JLL
# build number is bumped automatically on re-registration.
version = v"0.29.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaCI/apple-platform-rs.git",
              "f636669c18d53a20734426bf71628e852693f29f"),
]

# Bash recipe for building across all platforms
script = raw"""
    if [[ "${target}" == "aarch64-apple-darwin"* ]]; then
        # aws-lc requires the NEON and crypto extensions to be statically
        # enabled on Apple aarch64 (every Apple Silicon CPU has them, but
        # this clang does not enable them for bare arm64-apple-macosx).
        export CFLAGS="${CFLAGS} -march=armv8-a+crypto"
    fi

    if [[ "${target}" == *"freebsd"* ]]; then
        # liblzma's vendored xz needs the XSI namespace for gettimeofday(),
        # but _XOPEN_SOURCE hides the BSD APIs aws-lc uses (getentropy,
        # minherit), so hand aws-lc-sys a flag set without the define --
        # its builder prefers AWS_LC_SYS_CFLAGS over CFLAGS.
        export CFLAGS="${CFLAGS} -D_XOPEN_SOURCE=700"
        export AWS_LC_SYS_CFLAGS="-U_XOPEN_SOURCE"
    fi

    cd $WORKSPACE/srcdir/apple-platform-rs/
    cargo build --release --locked --package apple-codesign --features aws-kms --target-dir ${WORKSPACE}/tmp

    install_license apple-codesign/LICENSE
    install -Dvm 755 "${WORKSPACE}/tmp/${rust_target}/release/rcodesign${exeext}" "${bindir}/rcodesign${exeext}"
"""

# install a newer SDK which supports `kSecKeyAlgorithmRSASignatureMessagePSSSHA256`
sources, script = require_macos_sdk("11.0", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "riscv64", platforms) # rust toolchain not available
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> !(arch(p) == "armv6l" || arch(p) == "armv7l" || arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rcodesign", :rcodesign),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# `lock_microarchitecture=false` because the compiler wrappers otherwise
# reject the -march flag that aarch64-apple-darwin needs (see above).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"12.1.0", lock_microarchitecture = false)
