# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qiskit"
version = v"2.2.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Qiskit/qiskit.git", "8f33595f5b9e9c99b7aa81002655d13f48c8ac1b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
export PYTHONHOME=${prefix}
cd qiskit
mkdir -p target
export PYO3_PYTHON=/workspace/destdir/bin/python3
export RUSTFLAGS="-L ${libdir}"

# avoid 'cannot create cdylib' error on musl targets
# see https://github.com/rust-lang/cargo/issues/8607
#     https://github.com/rust-lang/rust/issues/59302
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

make C_CARGO_TARGET_DIR=target/${rust_target}/release -j${nproc} c
install -Dvm 755 "dist/c/lib/libqiskit.${dlext}" "${libdir}/libqiskit.${dlext}"
cp -vr "dist/c/include/*" "${includedir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libqiskit", :libqiskit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
    BuildDependency(PackageSpec(name="cbindgen_jll", uuid="a52b955f-5256-5bb0-8795-313e28591558"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
