using BinaryBuilder

name = "pixi"
version = v"0.50.2"

sources = [
    GitSource("https://github.com/prefix-dev/pixi.git", "99dc7563c9ce1276e8b7a96d00533c0481afce99"),
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
#TODO platforms = [
#TODO     # apple
#TODO     Platform("aarch64", "macos"),
#TODO     Platform("x86_64", "macos"),
#TODO     # windows
#TODO     # Platform("aarch64", "windows"),  # not supported by julia
#TODO     Platform("x86_64", "windows"),
#TODO     # linux
#TODO     Platform("aarch64", "linux"; libc="glibc"),
#TODO     Platform("x86_64", "linux"; libc="glibc"),
#TODO     Platform("x86_64", "linux"; libc="musl"),  # also happens to build
#TODO     Platform("powerpc64le", "linux"; libc="glibc"),  # also happens to build
#TODO ]
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pixi", :pixi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6", lock_microarchitecture=false,
               lazy_artifacts=true)
