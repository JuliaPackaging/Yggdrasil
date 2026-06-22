# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tectonic"
version = v"0.16.9"

# Collection of sources required to build tar
sources = [
    GitSource("https://github.com/tectonic-typesetting/tectonic.git",
              "66b6654103501b0a4a6926a7c450264be59cf927"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/tectonic

if [[ "${target}" == *-mingw* ]]; then
    export RUSTFLAGS="-Clink-args=-L${libdir}"
fi

cargo build --release --locked --features external-harfbuzz
install -Dvm 755 "target/${rust_target}/release/tectonic${exeext}" "${bindir}/tectonic${exeext}"
"""

platforms = supported_platforms()
# These platforms don't have a supported rust toolchain
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
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
    Dependency("HarfBuzz_ICU_jll"),
    Dependency("ICU_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
