# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MDLovoFit"
version = v"20.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/m3g/MDLovoFit.git", "a06c6048ecf43d4dad28ef2b995fd31610c732bc")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/MDLovoFit
install_license LICENSE
cmake .
make -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mdlovofit", :mdlovofit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
