# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Julia"
version = v"1.3.0"

sources = Dict(
	"x86_64-w64-mingw32" => ["https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-w64-mingw32.tar.gz" => "c7b2db68156150d0e882e98e39269301d7bf56660f4fc2e38ed2734a7a8d1551"], 
	"x86_64-linux-gnu" => ["https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-linux-gnu.tar.gz" => "44099e27a3d9ebdaf9d67bfdaf745c3899654c24877c76cbeff9cade5ed79139"],
	"x86_64-apple-darwin14" => ["https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-apple-darwin14.tar.gz" => "f2e5359f03314656c06e2a0a28a497f62e78f027dbe7f5155a5710b4914439b1"]
)

# Bash recipe for building across all platforms
script = raw"""
echo ${target}
find .
cd ${WORKSPACE}/srcdir/juliabin
rsync ./ ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    Windows(:x86_64;),
    MacOS(:x86_64)
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("julia", :julia),
    LibraryProduct("libjulia", :libjulia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

include("../../fancy_toys.jl")

# Build the tarballs, and possibly a `build.jl` as well.
for p in platforms
	should_build_platform(triplet(p)) && build_tarballs(ARGS, name, version, sources[triplet(p)], script, [p], products, dependencies)
end

