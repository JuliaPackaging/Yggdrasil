using BinaryBuilder

# Set sources and other environment variables.
name = "azurite"
version = v"3.18.0"
sources = [
    "https://github.com/Azure/Azurite" =>
    "dcf4bc444f2be8f95f0dfcde091ef22c68b4f4d8"
]

script = raw"""
cd ${WORKSPACE}/srcdir/Azurite
npm ci --force
npm run build
npm install --prefix ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: we match platforms supported by NodeJS_16_jll
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("powerpc64le", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="glibc", cxxstring_abi="cxx11"),

    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="musl", cxxstring_abi="cxx11"),

    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),

    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built.
products = [
    FileProduct("azurite/dist/src/azurite.js", :azurite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("NodeJS_16_jll"),
    "NodeJS_16_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
