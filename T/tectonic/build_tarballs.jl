# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tectonic"
version = v"0.1.15"

# Collection of sources required to build tar
sources = [
    ArchiveSource(
        "https://github.com/tectonic-typesetting/tectonic/archive/tectonic@$(version).tar.gz",
        "0e55188eafc1b58f3660a303fcdd6adc071051b9eb728119837fbeed2309914f"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tectonic-*/
cargo build --release -j${nproc}
cp target/${rust_target}/release/tectonic${exeext} ${bindir}/
"""

# Some platforms disabled for now due issues with rust and musl cross compilation. See #1673.
platforms = [
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="glibc"),
    # Platform("i686", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    # Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tectonic", :tectonic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Graphite2_jll"),
    Dependency("HarfBuzz_jll"),
    Dependency("ICU_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false)
