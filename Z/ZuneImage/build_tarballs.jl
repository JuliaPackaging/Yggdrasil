using BinaryBuilder, Pkg

name = "ZuneImage"
# Workspace release version; the zune-capi crate itself is still marked 0.5.0.
version = v"0.5.3"

sources = [
    GitSource("https://github.com/etemesi254/zune-image.git",
              "df468fb3e8e1d73c09ddd1363e41dbffb48870bd"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zune-image

# Crash fixes for the C bindings, see the patch headers; to be upstreamed.
for p in ${WORKSPACE}/srcdir/patches/*.patch; do atomic_patch -p1 "${p}"; done

install_license LICENSE-MIT LICENSE-APACHE LICENSE-ZLIB

if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

# Upstream's release profile has `debug = 2`, which makes the library ~100 MB.
export CARGO_PROFILE_RELEASE_DEBUG=0

# The crate declares a Rust `dylib`, not a C-ABI `cdylib`; override it here rather than patch the manifest.
cargo rustc -p zune-capi --release --lib --crate-type=cdylib -j${nproc} --target=${rust_target}

install -Dvm 755 target/${rust_target}/release/*zil_c.${dlext} -t "${libdir}"
install -Dvm 644 crates/zune-capi/include/zil.h "${includedir}/zil.h"
"""

platforms = supported_platforms()
# https://github.com/rust-lang/rust/issues/79609
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

products = [
    LibraryProduct(["libzil_c", "zil_c"], :libzil_c),
    FileProduct("include/zil.h", :zil_h),
]

# Rust's std links libiconv on Apple targets.
dependencies = [
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", compilers = [:c, :rust],
               preferred_rust_version = v"1.97.0")
