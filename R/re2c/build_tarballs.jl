# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "re2c"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/skvadrik/re2c/releases/download/3.0/re2c-3.0.tar.xz", "b3babbbb1461e13fe22c630a40c43885efcfbbbb585830c6f4c0d791cf82ba0b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/re2c-3.0/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j$nproc
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("re2go", :re2go),
    ExecutableProduct("re2rust", :re2rust),
    ExecutableProduct("re2c", :re2c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
