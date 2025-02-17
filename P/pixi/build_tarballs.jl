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

# build pixi
cargo build --release

# install pixi
install -Dvm 755 "target/${rust_target}/release/pixi${exeext}" "${bindir}/pixi${exeext}"
"""

# Supported platforms from https://github.com/prefix-dev/pixi/releases/latest
# plus x86_64-linux-musl and powerpc64le-linux-glibc which also happen to build
platforms = [
    # apple
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    # windows
    Platform("aarch64", "windows"),
    Platform("x86_64", "windows"),
    # linux
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pixi", :pixi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6", lazy_artifacts=true)
