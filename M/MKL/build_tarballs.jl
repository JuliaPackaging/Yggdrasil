using BinaryBuilder

name = "MKL"
version = v"2020.1.216"

sources = [
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/linux-64/mkl-2020.1-intel_217.tar.bz2",
                  "8814e952c0b4f28079361adac8bec1051b97d62dee621666798a3302e70d75e0"; unpack_target = "mkl-x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/osx-64/mkl-2020.1-intel_216.tar.bz2",
                  "4dab8dd1aa12b02cd121228ba881a887448399c799ee5a2d53942716a03f880e"; unpack_target = "mkl-x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/win-32/mkl-2020.1-intel_216.tar.bz2",
                  "b43ca7a8f5aed51e197af1f9165b3a72e5dd0a7f036fd9364ccfe90a8645a235"; unpack_target = "mkl-i686-w64-mingw32"),
    ArchiveSource("https://anaconda.org/intel/mkl/2020.1/download/win-64/mkl-2020.1-intel_216.tar.bz2",
                  "5dd8eff29b390ddb1cf15f391aba7fa3bdc4034f79b98d226865a5e331060f76"; unpack_target = "mkl-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mkl-${target}
if [[ ${target} == *mingw* ]]; then
    cp -r Library/bin/* ${libdir}
else
    cp -r lib/* ${libdir}
fi
install_license info/*.txt
"""

platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
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
no_autofix_platforms = [Windows(:i686), Windows(:x86_64), MacOS(:x86_64)]
autofix_platforms = [Linux(:x86_64)]
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
