using BinaryBuilder

name = "Pumpkin"
version = v"0.5.0"

sources = [
    GitSource("https://github.com/ConSol-Lab/Pumpkin.git",
              "b2574d46f8d5b64665f289e7f94e542994a73750"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/Pumpkin

# The checkers are only used by upstream's integration tests.  Disabling them
# avoids building target executables which Cargo would try to run on the host.
export NO_CHECKERS=true
cargo build --release --locked --package pumpkin-solver --bin pumpkin-solver

install -Dvm 755 \
    "target/${rust_target}/release/pumpkin-solver${exeext}" \
    "${bindir}/pumpkin-solver${exeext}"
install_license LICENSE-MIT LICENSE-APACHE
"""

platforms = supported_platforms(; experimental=true)
# BinaryBuilder does not provide usable Rust toolchains for these targets.
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

products = [
    ExecutableProduct("pumpkin-solver", :pumpkin_solver),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6")
