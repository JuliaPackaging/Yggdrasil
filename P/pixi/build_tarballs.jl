using BinaryBuilder

name = "pixi"
version = v"0.41.3"

sources = [
    GitSource("https://github.com/prefix-dev/pixi.git", "fc3e1a861deac099e51f7f0c3eaa2f64e217d4bf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd pixi

# not enough space in /tmp
export TMPDIR=$WORKSPACE/tmp
mkdir $TMPDIR

# the stack-size arg is wrong on windows, because we're using mingw not msvc
sed -i 's|/STACK:|-Wl,--stack,|' .cargo/config.toml
cat .cargo/config.toml

# build pixi
cargo build --release

# install pixi
install -D -m 755 "target/${rust_target}/release/pixi${exeext}" "${bindir}/pixi${exeext}"
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pixi", :pixi),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
