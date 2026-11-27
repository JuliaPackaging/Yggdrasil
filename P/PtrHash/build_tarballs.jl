# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PtrHash"
version = v"2.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/RagnarGrootKoerkamp/PtrHash.git",
              "7da31136d1c8952ac6cd4e54dffa27a8453329cb"), # v2.1.2
    # C ABI wrapper crate (`ptr_hash` is a pure Rust library without a C API)
    DirectorySource("./bundled"; target="ptrhash_c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ptrhash_c
if [[ "${target}" == *-musl* ]]; then
    # musl targets link statically by default, which cannot produce a cdylib
    export RUSTFLAGS="-C target-feature=-crt-static"
fi
# Build the wrapper against the dependency versions locked by PtrHash
cp ../PtrHash/Cargo.lock .
cargo build --release --verbose
install -Dvm 0755 "target/${rust_target}/release/"*ptrhash".${dlext}" "${libdir}/libptrhash.${dlext}"
install_license ../PtrHash/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# `sucds` requires 64-bit pointers
filter!(p -> nbits(p) == 64, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libptrhash", :libptrhash),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust],
               lock_microarchitecture=false)
