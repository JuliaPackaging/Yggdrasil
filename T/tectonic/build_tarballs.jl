# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "tectonic"
version = v"0.17.0"

# Collection of sources required to build tar
sources = [
    GitSource("https://github.com/tectonic-typesetting/tectonic.git",
              "8c0126a9653239a2e6e0a5274af9b8510f643030"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/tectonic

if [[ "${target}" == *-mingw* ]]; then
    export RUSTFLAGS="-Clink-args=-L${libdir}"
fi

# On FreeBSD, HarfBuzz_jll ships its pkg-config files in libdata/pkgconfig
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"

if [[ "${target}" == powerpc64le-* ]]; then
    # `aws-lc-sys` (rustls' crypto provider) reads AT_HWCAP2 in cpu_ppc64le.c.
    # The glibc headers of our powerpc64le toolchain predate that constant
    # (it has been 26 since Linux 3.10), so define it ourselves.
    export CFLAGS_powerpc64le_unknown_linux_gnu="-DAT_HWCAP2=26"
fi

cargo build --release --locked --features external-harfbuzz
install -Dvm 755 "target/${rust_target}/release/tectonic${exeext}" "${bindir}/tectonic${exeext}"
"""

# Some platforms disabled for now due issues with rust and musl cross compilation. See #1673.
platforms = supported_platforms()
# We dont have all dependencies for armv6l
filter!(p -> arch(p) != "armv6l", platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Musl used to build in 0.14 but does not in 0.15+
filter!(p -> libc(p) != "musl", platforms)
# These platforms don't have a supported rust toolchain
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
platforms = expand_cxxstring_abis(platforms)

# `reqwest` pulls in `rustls-platform-verifier` -> `security-framework`, which
# calls `SecTrustEvaluateWithError()`. That symbol was introduced in macOS 10.14,
# so the default SDK used for `x86_64-apple-darwin14` fails to link. Use the
# same SDK the aarch64 builder already uses; the deployment target is kept
# lower than the SDK so the minimum macOS version does not rise needlessly.
sources, script = require_macos_sdk("11.1", sources, script; deployment_target = "10.15")

# The products that we will ensure are always built
products = [
    ExecutableProduct("tectonic", :tectonic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"; compat="2.17.1"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("Graphite2_jll"; compat="1.3.15"),
    # HarfBuzz_ICU_jll ≥ 8.5.1 is built against ICU 76, and the ICU symbols
    # carry the major version in their names, so the ICU pin here has to
    # match the one HarfBuzz_ICU_jll was built with.
    Dependency("HarfBuzz_jll"; compat="100.14003"),
    Dependency("HarfBuzz_ICU_jll"; compat="100.14003"),
    Dependency("ICU_jll"; compat="76.2"),
    # tectonic 0.17 fetches bundles through reqwest with rustls; OpenSSL is no
    # longer linked (there is no openssl-sys in the build), so OpenSSL_jll is gone.
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
