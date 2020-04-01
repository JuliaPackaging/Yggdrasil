# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Pkg
using BinaryBuilder

name = "Libtask"
version = v"0.3.0"
commit_id = "4e201c561cd73c2fc22ccff854f5865ef4b06cc9"

# see https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/336
# ENV["CI_COMMIT_TAG"] = ENV["TRAVIS_TAG"] = "v" * string(version)

sources = [
    "https://github.com/TuringLang/Libtask.jl.git" => commit_id,
]

# Bash recipe for building across all platforms
script = read(joinpath(dirname(@__FILE__), "build_dylib.sh"), String)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    # Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:aarch64),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libtask_v1_0", :libtask_v1_0)
    LibraryProduct("libtask_v1_1", :libtask_v1_1)
    LibraryProduct("libtask_v1_2", :libtask_v1_2)
    LibraryProduct("libtask_v1_3", :libtask_v1_3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
# build_file = "products/build_$(name).v$(version).jl"
build_tarballs(ARGS, name, version, sources,
               script, platforms, products, dependencies)
