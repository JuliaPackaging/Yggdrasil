using BinaryBuilder

name = "IntelOpenMP"
version = v"2018.0.3"

target = triplet(platform_key(ARGS[end]))
if target == "unknown-unknown-unknown"
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

source_dict = Dict(
    "x86_64-linux-gnu" => (
        "https://anaconda.org/intel/openmp/2018.0.3/download/linux-64/openmp-2018.0.3-intel_0.tar.bz2" =>
        "cae3ef59d900f12c723a3467e7122b559f0388c08c40c332da832131c024409b"
    ),
    "i686-linux-gnu" => (
        "https://anaconda.org/intel/openmp/2018.0.3/download/linux-32/openmp-2018.0.3-intel_0.tar.bz2" =>
        "f06edc0c52337658fd4b780d0b5c704b0ffb1c156dced7f5038c1ebbda3d891b"
    ),
    "x86_64-w64-mingw32" => (
        "https://anaconda.org/intel/openmp/2018.0.3/download/win-64/openmp-2018.0.3-intel_0.tar.bz2" =>
        "0aee3d9debb8b1c2bb9a202b780c2b2d2179e4cee9158f7d0ad46125cf6f3fa2"
    ),
    "i686-w64-mingw32" => (
        "https://anaconda.org/intel/openmp/2018.0.3/download/win-32/openmp-2018.0.3-intel_0.tar.bz2" =>
        "86ed603332ed7b4004e8a474943468589b222ef16d0d9aaf3ebb4ceaf743a39d"
    ),
    "x86_64-apple-darwin14" => (
        "https://anaconda.org/intel/openmp/2018.0.3/download/osx-64/openmp-2018.0.3-intel_0.tar.bz2" =>
        "110b94d5ff3c4df66fc89030c30ad42378da02817b3962f14cb5c268f9d94dae"
    ),
)
sources = [
    source_dict[target],
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ ${target} == *mingw* ]]; then
    mv Library/bin ${prefix}/bin
else
    mv lib ${prefix}/lib
fi
mkdir -p ${prefix}/share
mv info/*.txt ${prefix}/share/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [platform_key_abi(target)]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libiomp5", :libiomp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
