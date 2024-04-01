# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rcodesign"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/indygreg/PyOxidizer/archive/refs/tags/apple-codesign/$(version).tar.gz",
                  "3139080097ce3e8d70d05e49f984f5adb4d2fa9a3e095662411422c7c56eba8b"),
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
cd $WORKSPACE/srcdir/PyOxidizer-apple-codesign-*/apple-codesign/
cargo build --release
install -Dvm 755 "../target/${rust_target}/release/rcodesign${exeext}" "${bindir}/rcodesign${exeext}"
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Build for PowerPC fails with
#     error: failed to run custom build command for `ring v0.16.20`
#
#     Caused by:
#       process didn't exit successfully: `/workspace/srcdir/PyOxidizer-apple-codesign-0.17.0/target/release/build/ring-f26cfe5ece208e2f/build-script-build` (exit status: 101)
#       --- stderr
#       thread 'main' panicked at 'called `Option::unwrap()` on a `None` value', /opt/x86_64-linux-musl/registry/src/github.com-1ecc6299db9ec823/ring-0.16.20/build.rs:358:10
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rcodesign", :rcodesign),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
