# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Pkg
using BinaryBuilder

name = "Libtask"
version = v"0.3.2"
commit_id = "fbe338053f402d76524d0a01f3796dd7da90b781"

# see https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/336
# ENV["CI_COMMIT_TAG"] = ENV["TRAVIS_TAG"] = "v" * string(version)

sources = [
    "https://github.com/TuringLang/Libtask.jl.git" => commit_id,
]

# Bash recipe for building across all platforms
script_file = joinpath(@__DIR__, "build_dylib.sh")
if !isfile(script_file) # when run generate_buildjl.jl
    script_file = joinpath(@__DIR__, "L/Libtask/build_dylib.sh")
end
script = read(script_file, String)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="glibc"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows")
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
