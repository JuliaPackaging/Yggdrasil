# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tectonic"
version = v"0.8.0"

# Collection of sources required to build tar
sources = [
    ArchiveSource(
        "https://github.com/tectonic-typesetting/tectonic/archive/tectonic@$(version).tar.gz",
        "794cf34aee017b8a4288ed509a4e9d550a36aadc2bc0d35b1727d1135dac8e02"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tectonic-*/
cargo build --release -j${nproc} --target ${rust_target}
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
    Platform("aarch64", "macos"),    
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
    Dependency("ICU_jll", v"69.1"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
