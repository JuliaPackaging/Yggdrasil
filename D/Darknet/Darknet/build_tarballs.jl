using BinaryBuilder
using Pkg

name = "Darknet"

include("../common.jl")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# # skip CXX03 string ABI because of many incompatibilities for loop declarations
filter!(p -> cxxstring_abi(p) != "cxx03", platforms)

# # same for old intel macOS
filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)

# Hitting ./src/utils.c:21:22: fatal error: execinfo.h: No such file or directory
filter!(p -> libc(p) ≠ "musl", platforms)

version, sources, script, products, dependencies = gen_common(platforms; gpu=false)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10")

