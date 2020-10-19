using BinaryBuilder

name = "MKL"
version = v"2020.2.254"

sources = [
    ArchiveSource("https://anaconda.org/intel/mkl/2020.2/download/linux-64/mkl-2020.2-intel_254.tar.bz2",
                  "930d67bb4298c6da2dabb8ea068170e69e9304fc0ce1b4fc094af01851102a35"; unpack_target = "mkl-x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.2/download/osx-64/mkl-2020.2-intel_258.tar.bz2",
                  "628c54329ab3c088b4c55d047ccb58feeb2ade7d6e50bf982aa51ac088cccd45"; unpack_target = "mkl-x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.2/download/win-32/mkl-2020.2-intel_254.tar.bz2",
                  "19dfae9402e764e507ee143b2c22cbf091fd6b778b03620504addc2b8135f987"; unpack_target = "mkl-i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.2/download/win-64/mkl-2020.2-intel_254.tar.bz2",
                  "99efbdd8014668f1683aec61ea190aa7182a90e14969439a7dfb7b3dfef55693"; unpack_target = "mkl-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mkl-${target}
if [[ ${target} == *mingw* ]]; then
    cp -r Library/bin/* ${libdir}
    install_license info/*.txt
else
    cp -r lib/* ${libdir}
    install_license info/licenses/*.txt
fi
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("IntelOpenMP_jll"),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
include("../../fancy_toys.jl")
no_autofix_platforms = [Platform("i686", "windows"), Platform("x86_64", "windows"), Platform("x86_64", "macos")]
autofix_platforms = [Platform("x86_64", "linux")]
if any(should_build_platform.(triplet.(no_autofix_platforms)))
    # Need to disable autofix: updating linkage of libmkl_intel_thread.dylib on
    # macOS causes runtime issues:
    # https://github.com/JuliaPackaging/Yggdrasil/issues/915.
    build_tarballs(non_reg_ARGS, name, version, sources, script, no_autofix_platforms, products, dependencies; lazy_artifacts = true, autofix = false)
end
if any(should_build_platform.(triplet.(autofix_platforms)))
    # ... but we need to run autofix on Linux, because here libmkl_rt doesn't
    # have a soname, so we can't ccall it without specifying the path:
    # https://github.com/JuliaSparse/Pardiso.jl/issues/69
    build_tarballs(ARGS, name, version, sources, script, autofix_platforms, products, dependencies; lazy_artifacts = true)
end
