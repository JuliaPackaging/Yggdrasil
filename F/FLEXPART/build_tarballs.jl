
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLEXPART"
version = v"10.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://www.flexpart.eu/gitmob/flexpart", "8ad70c708b59dad8f4adabf7ab51dd110ace76d1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# The flexpart-parmod.patch modify some parameters to extend the size of 
# the meteorological input files and the maximum number of particules that FLEXPART can handle.
script = raw"""
cd flexpart
atomic_patch -p1 /workspace/srcdir/patches/flexpart-makefile.patch
atomic_patch -p1 /workspace/srcdir/patches/flexpart-parmod.patch
cd src
make ncf=yes
cp FLEXPART $bindir
install_license ../LICENSE
"""

platforms = supported_platforms()
# 32 bit platforms are not supported by dependency eccodes
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) != v"3", platforms) # Also for eccodes compatibility
filter!(p -> arch(p) != "powerpc64le" && !Sys.isfreebsd(p) && libc(p) != "musl", platforms) # Fliter for netcdff platforms
filter!(!Sys.iswindows, platforms) # Excluded because of "Error: value of ... too large for field of 4 bytes at ..."
filter!(!Sys.isapple, platforms) # Excluded because of "invalid variant" errors

# The products that we will ensure are always built
products = [
    ExecutableProduct("FLEXPART", :FLEXPART),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("eccodes_jll"; compat="2.36.0"),
    Dependency("NetCDFF_jll"; compat="4.6.1"),
    Dependency("JasPer_jll"; compat="2.0.33"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
julia_compat = "1.6")
