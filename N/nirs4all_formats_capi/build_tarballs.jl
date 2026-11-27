# BinaryBuilder recipe for nirs4all_formats_capi_jll, the C ABI of nirs4all-formats.
#
# Copy this directory to N/nirs4all_formats_capi/ in a fork of
# https://github.com/JuliaPackaging/Yggdrasil and open a pull request; the
# Yggdrasil CI builds every platform and registers the JLL in General. For a new
# release, update `version` and the commit hash of the matching v<version> tag.
# See docs/bindings/julia.md in nirs4all-formats.

using BinaryBuilder, Pkg

name = "nirs4all_formats_capi"
version = v"0.3.1"

sources = [
    # Commit of the v0.3.1 tag of https://github.com/GBeurier/nirs4all-formats.
    GitSource("https://github.com/GBeurier/nirs4all-formats.git",
              "89f191396772c71379e7ad788f29f30472369498"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/nirs4all-formats
# Rust's musl targets link the C runtime statically, which rules out a cdylib.
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi
cargo build --release --locked -p nirs4all-formats-capi
if [[ "${target}" == *-mingw* ]]; then
    install -Dvm 755 "target/${rust_target}/release/nirs4all_formats_capi.${dlext}" "${libdir}/nirs4all_formats_capi.${dlext}"
else
    install -Dvm 755 "target/${rust_target}/release/libnirs4all_formats_capi.${dlext}" "${libdir}/libnirs4all_formats_capi.${dlext}"
fi
install -Dvm 644 crates/nirs4all-formats-capi/include/nirs4all_formats.h "${includedir}/nirs4all_formats.h"
install_license LICENSE LICENSING.md LICENSES/CeCILL-2.1.txt LICENSES/AGPL-3.0-or-later.txt
"""

platforms = supported_platforms()
# The C sources of zstd-sys and liblzma-sys (compression codecs of the HDF5 and
# archive readers) fail to compile for i686, armv6l, armv7l and riscv64
# ("failed to run custom build command for zstd-sys" in the Yggdrasil CI log).
filter!(p -> nbits(p) == 64 && arch(p) != "riscv64", platforms)

products = [
    LibraryProduct(["libnirs4all_formats_capi", "nirs4all_formats_capi"], :libnirs4all_formats_capi),
    FileProduct("include/nirs4all_formats.h", :nirs4all_formats_h),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6")
