using BinaryBuilder, Pkg

# JLL-Paketname gemäß Yggdrasil-Konvention: Bibliotheksname ohne lib-Prefix, CamelCase
name    = "TypeDBDriverClib_jll"
version = v"3.8.1"

sources = [
    GitSource(
        "https://github.com/typedb/typedb-driver.git",
        "8e8d4a43da32adc1c56084f4d34174bebd0ce34a",  # tag 3.8.1
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/typedb-driver

# BinaryBuilder setzt CARGO_BUILD_TARGET bei Cross-Compilation.
# Bei nativem Build liegt das Ergebnis in target/release/.
cargo build --release --manifest-path c/Cargo.toml

if [ -n "${CARGO_BUILD_TARGET}" ]; then
    CARGO_OUT="target/${CARGO_BUILD_TARGET}/release"
else
    CARGO_OUT="target/release"
fi

mkdir -p "${libdir}"

if [[ "${target}" == *-apple-darwin* ]]; then
    install -vm 755 "${CARGO_OUT}/libtypedb_driver_clib.dylib" "${libdir}/"
elif [[ "${target}" == *-linux-* ]]; then
    install -vm 755 "${CARGO_OUT}/libtypedb_driver_clib.so"    "${libdir}/"
elif [[ "${target}" == *-w64-mingw* ]]; then
    # Windows: Rust erzeugt typedb_driver_clib.dll (ohne lib-Prefix)
    install -vm 755 "${CARGO_OUT}/typedb_driver_clib.dll" "${libdir}/"
else
    echo "ERROR: Unsupported target ${target}" >&2
    exit 1
fi
"""

platforms = [
    Platform("x86_64",  "linux";   libc="glibc"),
    Platform("aarch64", "linux";   libc="glibc"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64",  "windows"),
]

# Rust-Bibliotheken müssen für jede C++-ABI-Variante gebaut werden,
# da sie über Cargo-Dependencies C++-Code einziehen können.
platforms = expand_cxxstring_abis(platforms)

products = [
    # LibraryProduct akzeptiert eine Liste möglicher Namen (lib-Prefix optional auf Windows)
    LibraryProduct(["libtypedb_driver_clib", "typedb_driver_clib"], :libtypedb_driver_clib),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers    = [:c, :rust],
               julia_compat = "1.6")
