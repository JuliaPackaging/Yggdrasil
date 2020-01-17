using BinaryBuilder

name = "MKL"
version = v"2019.0.117"

sources_win32 = [
    "https://anaconda.org/intel/mkl/2019.1/download/win-32/mkl-2019.1-intel_144.tar.bz2" =>
    "6a765f0243843d1fde02f0de3c10b0de7848467b66560d0bc0bb5c47fbebb976",
]

sources_win64 = [
    "https://anaconda.org/intel/mkl/2019.1/download/win-64/mkl-2019.1-intel_144.tar.bz2" =>
    "b25cdece9ba297be8f28ac62fb9b2fd8b6432b2635094c21cd845f9dd24e5fae",
]

sources_macos = [
    "https://anaconda.org/intel/mkl/2019.1/download/osx-64/mkl-2019.1-intel_144.tar.bz2" =>
    "a11faf3227ecac3732172402de0e9be1627361802aea89f5c7bede47cc53b070"
]

sources_linux32 = [
    "https://anaconda.org/intel/mkl/2019.1/download/linux-32/mkl-2019.1-intel_144.tar.bz2" =>
    "b1510216a709a5e5d0e54ecab361555b6e62edd4c2b8f83e3fe9d0c4fa66dae0"
]

sources_linux64 = [
    "https://anaconda.org/intel/mkl/2019.1/download/linux-64/mkl-2019.1-intel_144.tar.bz2" =>
    "f4a753d28bf26905a93ea481827277340221674a80b53a8a2eb6a34f44d70f84"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ ${target} == *mingw* ]]; then
    cp -r Library/bin/* ${libdir}
else
    cp -r lib/* ${libdir}
fi
install_license info/*.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "IntelOpenMP_jll",
]

# Install first for win32, then win64.  This will accumulate files into `products` and also wrappers into the JLL package.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

include("../../fancy_toys.jl")

if should_build_platform("i686-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_win32, script, [Windows(:i686)], products, dependencies; lazy_artifacts = true)
end
if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_win64, script, [Windows(:x86_64)], products, dependencies; lazy_artifacts = true)
end
if should_build_platform("x86_64-apple-darwin14")
    build_tarballs(non_reg_ARGS, name, version, sources_macos, script, [MacOS(:x86_64)], products, dependencies; lazy_artifacts = true)
end
if should_build_platform("i686-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux32, script, [Linux(:i686)], products, dependencies; lazy_artifacts = true)
end
if should_build_platform("x86_64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux64, script, [Linux(:x86_64)], products, dependencies; lazy_artifacts = true)
end
