using BinaryBuilder

name = "Hayagriva"
version = v"0.4.0"

sources = [
    GitSource("https://github.com/typst/hayagriva.git",
                  "8dce242de6366156eee2ea113584236883af6e66"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hayagriva/
cargo build --release --features cli
install -D -m 755 "target/${rust_target}/release/hayagriva${exeext}" "${bindir}/hayagriva${exeext}"
install_license LICENSE-MIT LICENSE-APACHE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> !(Sys.iswindows(p) && arch(p) == "i686"), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("hayagriva", :hayagriva),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
