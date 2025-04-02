# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rcodesign"
version = v"0.29.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/indygreg/apple-platform-rs/archive/refs/tags/apple-codesign/$(version).tar.gz", "e92e27c2d0738523b5f0bfc2da5dbab33601568cfeff3e1d40eadd0ffb8e5a98"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.0.sdk.tar.xz",
                  "d3feee3ef9c6016b526e1901013f264467bb927865a03422a9cb925991cc9783"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    #install a newer SDK which supports `kSecKeyAlgorithmRSASignatureMessagePSSSHA256`
    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/*
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

cd $WORKSPACE/srcdir/apple-platform-rs-apple-codesign-*/
cargo build --release --package apple-codesign --target-dir ${WORKSPACE}/tmp

install_license apple-codesign/LICENSE
install -Dvm 755 "${WORKSPACE}/tmp/${rust_target}/release/rcodesign${exeext}" "${bindir}/rcodesign${exeext}"
"""

script = replace(script, raw"$version" => version)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("rcodesign", :rcodesign),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"12.1.0")
