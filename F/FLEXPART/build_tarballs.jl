
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLEXPART"
version = v"11.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.phaidra.org/flexpart/flexpart", "59eb95e770490f551425cdb30432f82693d585bc"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# The flexpart-parmod.patch modify some parameters to extend the size of 
# the meteorological input files and the maximum number of particules that FLEXPART can handle.
script = raw"""
cd flexpart
atomic_patch -p1 /workspace/srcdir/patches/flexpart-makefile.patch
cd src
make -f makefile_gfortran eta=yes ncf=yes
cp FLEXPART_ETA $bindir
install_license ../LICENSE
"""

platforms = supported_platforms()
# 32 bit platforms are not supported by dependency eccodes
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) != v"3", platforms) # Also for eccodes compatibility
filter!(p -> libgfortran_version(p) != v"4", platforms) # Needs support for higher dimension arrays
filter!(p -> arch(p) != "powerpc64le" && arch(p) != "riscv64" && !Sys.isfreebsd(p) && libc(p) != "musl", platforms) # Fliter for netcdff platforms
filter!(!Sys.iswindows, platforms) # Excluded because of "Error: value of ... too large for field of 4 bytes at ..."
filter!(!Sys.isapple, platforms) # Excluded because of "invalid variant" errors

# The products that we will ensure are always built
products = [
    ExecutableProduct("FLEXPART_ETA", :FLEXPART),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("eccodes_jll"; compat="2.36.0"),
    Dependency("NetCDFF_jll"; compat="4.6.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
julia_compat = "1.6")
