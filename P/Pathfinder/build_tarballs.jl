using BinaryBuilder

name = "Pathfinder"
version = v"0.5.0"
sources = [
    GitSource("https://github.com/servo/pathfinder.git", "7281a607a80dacc5470d7d3ec208341b6f0b0727"),
    DirectorySource("./bundled")
]

script = raw"""
cd ${WORKSPACE}/srcdir/pathfinder*

# by default, pathfinder will compile to a static library,
# so we change "staticlib" to "cdylib" to compile to a dynamic library
atomic_patch -p1 ../patches/Compile-to-dynamic-lib.patch

# we need cbindgen to generate the header file
cargo install cbindgen --force --target x86_64-unknown-linux-musl

cd c

# generate the header file
cbindgen \
    --lang c \
    --crate pathfinder_c \
    --config cbindgen.toml \
    --output "${includedir}/pathfinder.h"

# build pathfinder
cargo build --release --lib --target=${rust_target}

# On windows the generated .dll doesn't start with lib
if [[ "${target}" == *-mingw* ]]; then
    cp \
        ../target/${rust_target}/release/pathfinder.dll \
        ../target/${rust_target}/release/libpathfinder.dll
fi

# install the library
install -D -m 755 "../target/${rust_target}/release/libpathfinder.${dlext}" "${libdir}/libpathfinder.${dlext}"

# install the licenses
install_license ../LICENSE-APACHE ../LICENSE-MIT
"""

platforms = supported_platforms(; experimental=true)

# font-kit fails to compile on arm and i686 linux
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)
filter!(p -> !Sys.islinux(p) || arch(p) != "i686", platforms)
# cdylib apparently doesn't support musl
filter!(p -> libc(p) != "musl", platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

products = [
    LibraryProduct("libpathfinder", :libpathfinder),
]

not_windows = filter(!Sys.iswindows, platforms)

dependencies = [
    BuildDependency("Fontconfig_jll", platforms=not_windows),
    BuildDependency("FreeType2_jll",  platforms=not_windows),
    BuildDependency("HarfBuzz_jll",   platforms=not_windows),
]

compilers = [:rust, :c]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers, julia_compat="1.6")
