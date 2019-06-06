using BinaryBuilder, Pkg

name = "MKL"
version = v"2019.0.117"

target = triplet(platform_key_abi(ARGS[end]))
if target == "unknown-unknown-unknown"
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

source_dict = Dict(
    "x86_64-linux-gnu" => (
        "https://anaconda.org/intel/mkl/2019.1/download/linux-64/mkl-2019.1-intel_144.tar.bz2" =>
        "f4a753d28bf26905a93ea481827277340221674a80b53a8a2eb6a34f44d70f84"
    ),
    "i686-linux-gnu" => (
        "https://anaconda.org/intel/mkl/2019.1/download/linux-32/mkl-2019.1-intel_144.tar.bz2" =>
        "b1510216a709a5e5d0e54ecab361555b6e62edd4c2b8f83e3fe9d0c4fa66dae0"
    ),
    "x86_64-w64-mingw32" => (
        "https://anaconda.org/intel/mkl/2019.1/download/win-64/mkl-2019.1-intel_144.tar.bz2" =>
        "b25cdece9ba297be8f28ac62fb9b2fd8b6432b2635094c21cd845f9dd24e5fae"
    ),
    "i686-w64-mingw32" => (
        "https://anaconda.org/intel/mkl/2019.1/download/win-32/mkl-2019.1-intel_144.tar.bz2" =>
        "6a765f0243843d1fde02f0de3c10b0de7848467b66560d0bc0bb5c47fbebb976"
    ),
    "x86_64-apple-darwin14" => (
        "https://anaconda.org/intel/mkl/2019.1/download/osx-64/mkl-2019.1-intel_144.tar.bz2" =>
        "a11faf3227ecac3732172402de0e9be1627361802aea89f5c7bede47cc53b070"
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
products = [
    LibraryProduct(["libmkl_core", "mkl_core"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
