using BinaryBuilder, Pkg

name = "Pathfinder"
version = v"0.5.0"

sources = [
    GitSource("https://github.com/servo/pathfinder.git",
              "7281a607a80dacc5470d7d3ec208341b6f0b0727"),
    DirectorySource("./bundled")
]

script = raw"""
cd ${WORKSPACE}/srcdir/pathfinder*/c

# by default, pathfinder will compile to a static library,
# so we change "staticlib" to "cdylib" to compile to a dynamic library
atomic_patch -d .. -p1 ../../patches/Compile-to-dynamic-lib.patch

# generate the header file
cbindgen \
    --lang c \
    --crate pathfinder_c \
    --config cbindgen.toml \
    --output "${includedir}/pathfinder.h"

# build pathfinder
cargo build --release --lib --target=${rust_target}

# install the library
install -Dvm 755 ../target/${rust_target}/release/*pathfinder.${dlext} "${libdir}/libpathfinder.${dlext}"

# install the licenses
install_license ../LICENSE-APACHE ../LICENSE-MIT
"""

platforms = supported_platforms()

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
    Dependency("Fontconfig_jll", platforms=not_windows),
    Dependency("FreeType2_jll",  platforms=not_windows, compat="2.10.4"),
    Dependency("HarfBuzz_jll",   platforms=not_windows),
    HostBuildDependency(PackageSpec(; name="cbindgen_jll", uuid="a52b955f-5256-5bb0-8795-313e28591558")),
]

compilers = [:rust, :c]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers, julia_compat="1.6")
