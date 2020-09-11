# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build GMP
name = "libjulia"

sources = [
    ArchiveSource("https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version)-full.tar.gz", checksum),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/julia-*

# patch `make install` to not install Julia files or sysimage
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/Makefile.patch

# compile libjulia but don't try to build a sysimage
make -j${nproc} julia-ui-release
make install
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built/used
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
