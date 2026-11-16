# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fmusim"
version = v"0.15.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/modelica/fmusim.git",
              "d6f28792ed17ea3398128fbb89b7c43858841052"; tag="v$(version)"),
    # The fmi-rs crate downloads and builds static Sundials and libxml2 in its
    # build script, so we build a patched copy that links the JLLs instead.
    GitSource("https://github.com/CATIA-Systems/fmi-rs.git",
              "95b7a56653fa3ba299f5bb8f0fb4a03016a923fc"; tag="v0.3.4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/fmi-rs
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fmi-rs-use-shared-deps.patch

cd ${WORKSPACE}/srcdir/fmusim
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/test-fixtures-dev-dependency.patch

export CFLAGS="-I${includedir}/libxml2"
# On Windows the import libraries are in ${prefix}/lib, not ${libdir}.
export RUSTFLAGS="-L ${prefix}/lib"
if [[ "${target}" == *-mingw* ]]; then
    # crash-handler calls _invoke_watson, which mingw-w64 v11 lacks for msvcrt.dll.
    ${CC} -c ${WORKSPACE}/srcdir/invoke_watson.c -o ${WORKSPACE}/srcdir/invoke_watson.o
    export RUSTFLAGS="${RUSTFLAGS} -C link-arg=${WORKSPACE}/srcdir/invoke_watson.o"
fi
cargo build --release --config "patch.crates-io.fmi-rs.path='${WORKSPACE}/srcdir/fmi-rs/fmi-rs'"

install -Dvm 755 "target/${rust_target}/release/fmusim${exeext}" "${bindir}/fmusim${exeext}"
install_license LICENSE
"""

# Upstream supports only x86_64 / aarch64 on linux/macos/windows.
platforms = filter(supported_platforms()) do p
    os(p) in ("linux", "macos", "windows") &&
        arch(p) in ("x86_64", "aarch64") &&
        libc(p) != "musl"
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("fmusim", :fmusim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Sundials_jll"; compat="7.4"),
    Dependency("XML2_jll"; compat="2.15.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Sundials_jll's KLU solver needs libklu 2, which Julia ships from 1.10 on.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", compilers=[:c, :rust], preferred_gcc_version=v"9")
