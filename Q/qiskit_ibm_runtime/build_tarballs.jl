# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qiskit_ibm_runtime"
version = v"0.38.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Qiskit/qiskit-ibm-runtime-c.git", "b7e4838640b56610c25d3776036dcf1ef7766fea")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qiskit-ibm-runtime-c
export PYO3_PYTHON=/usr/bin/python3
export PYO3_CROSS_LIB_DIR=$WORKSPACE/destdir/lib
export RUSTFLAGS="-L ${libdir} -lqiskit"

# avoid 'cannot create cdylib' error on musl targets
# see https://github.com/rust-lang/cargo/issues/8607
#     https://github.com/rust-lang/rust/issues/59302
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

cargo build --release --locked --manifest-path ./crates/client/Cargo.toml

install -Dvm 755 "target/${rust_target}/release/libqiskit_ibm_runtime.${dlext}" "${libdir}/libqiskit_ibm_runtime.${dlext}"
cp -vr include/* "${includedir}"
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libqiskit_ibm_runtime", :libqiskit_ibm_runtime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="cbindgen_jll", uuid="a52b955f-5256-5bb0-8795-313e28591558"))
    Dependency(PackageSpec(name="Qiskit_jll", uuid="b54e8e98-f244-53b3-a8e8-4727a4907f76"); compat="~2.2.3")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
