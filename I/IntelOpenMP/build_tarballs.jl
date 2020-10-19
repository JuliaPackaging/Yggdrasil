using BinaryBuilder

name = "IntelOpenMP"
version = v"2018.0.3"

sources_win32 = [
    "https://anaconda.org/intel/openmp/2018.0.3/download/win-32/openmp-2018.0.3-intel_0.tar.bz2" =>
    "86ed603332ed7b4004e8a474943468589b222ef16d0d9aaf3ebb4ceaf743a39d",
]

sources_win64 = [
    "https://anaconda.org/intel/openmp/2018.0.3/download/win-64/openmp-2018.0.3-intel_0.tar.bz2" =>
    "0aee3d9debb8b1c2bb9a202b780c2b2d2179e4cee9158f7d0ad46125cf6f3fa2",
]

sources_macos = [
    "https://anaconda.org/intel/openmp/2018.0.3/download/osx-64/openmp-2018.0.3-intel_0.tar.bz2" =>
    "110b94d5ff3c4df66fc89030c30ad42378da02817b3962f14cb5c268f9d94dae"
]

sources_linux32 = [
    "https://anaconda.org/intel/openmp/2018.0.3/download/linux-32/openmp-2018.0.3-intel_0.tar.bz2" =>
    "f06edc0c52337658fd4b780d0b5c704b0ffb1c156dced7f5038c1ebbda3d891b",
]

sources_linux64 = [
    "https://anaconda.org/intel/openmp/2018.0.3/download/linux-64/openmp-2018.0.3-intel_0.tar.bz2" =>
    "cae3ef59d900f12c723a3467e7122b559f0388c08c40c332da832131c024409b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ ${target} == *mingw* ]]; then
    mv Library/bin ${libdir}
else
    mv lib ${libdir}
fi
install_license info/*.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Install first for win32, then win64.  This will accumulate files into `products` and also wrappers into the JLL package.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

include("../../fancy_toys.jl")

if should_build_platform("i686-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_win32, script, [Platform("i686", "windows")], products, [])
end
if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_win64, script, [Platform("x86_64", "windows")], products, [])
end
if should_build_platform("x86_64-apple-darwin14")
    build_tarballs(non_reg_ARGS, name, version, sources_macos, script, [Platform("x86_64", "macos")], products, [])
end
if should_build_platform("i686-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux32, script, [Platform("i686", "linux")], products, [])
end
if should_build_platform("x86_64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux64, script, [Platform("x86_64", "linux")], products, [])
end
