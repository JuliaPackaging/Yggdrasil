using BinaryBuilder

name = "MacOSLibc"
version = v"10.10"

# sources to build, such as mingw32, our patches, etc....
sources = [
    "https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.10.sdk.tar.xz" =>
    "4a08de46b8e96f6db7ad3202054e28d7b3d60a3d38cd56e61f08fb4863c488ce"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MacOSX*.sdk
sysroot="${prefix}/${target}/sys-root"

mkdir -p "${sysroot}"
mv * "${sysroot}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    MacOS(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(joinpath(prefix, "usr", "lib"), "libSystem", :libSystem),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
