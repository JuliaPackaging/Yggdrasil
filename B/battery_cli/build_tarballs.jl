using BinaryBuilder

name = "battery_cli"
version = v"0.10.0"

# Collection of sources required to build ghr
sources = [
    GitSource("https://github.com/distatus/battery.git", "aa540e5be8de3bd83449b7a099341109e9ac1153"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/battery/cmd/battery
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("battery", :battery),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
