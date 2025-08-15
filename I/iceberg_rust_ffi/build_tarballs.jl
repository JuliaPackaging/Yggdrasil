using BinaryBuilder

name = "iceberg_rust_ffi"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/RelationalAI/iceberg_rust_ffi.git", "583c8f2c2cc5cb5f92100ad8eae32f22b7a76c09"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/iceberg_rust_ffi/

# Build the library with native compilation
cargo rustc --release --lib --crate-type=cdylib

# Install the library
install -Dvm 755 "target/${rust_target}/release/libiceberg_rust_ffi.${dlext}" "${libdir}/libiceberg_rust_ffi.${dlext}"
"""

# We could potentially support more platforms, if required.
# Except perhaps i686 Windows and Musl systems.
platforms = [
    Platform("aarch64", "macos"),
    Platform("x86_64",  "linux"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libiceberg_rust_ffi", :libiceberg_rust_ffi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers=[:c, :rust], julia_compat="1.10", preferred_gcc_version=v"5", dont_dlopen=true,
)
