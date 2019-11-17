using BinaryBuilder

name = "HelloWorldRust"
version = v"1.0.0"

# No sources, we're just building the testsuite
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
rustc -o ${prefix}/bin/hello_world${exeext} -g /usr/share/testsuite/rust/hello_world/hello_world.rs
"""

# We build for a restricted set of platforms, because our rust toolchain is a little broken
platforms = supported_platforms()

# First, FreeBSD has -fPIC problems when linking in `crt.o`
filter!(p -> !isa(p, FreeBSD), platforms)

# Next, :musl libcs have a hard time linking
filter!(p -> libc(p) != :musl, platforms)

# Finally, windows seems to be broken
# https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/499
filter!(p -> !isa(p, Windows), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
