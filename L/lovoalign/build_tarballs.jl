# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lovoalign"
version = v"20.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/m3g/lovoalign.git", "cba28738a5a945475570f5869b2efe9c0c2573eb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lovoalign
if [[ $target == *"w64-mingw32" ]]; then
    sed -i 's/blastrampoline/blastrampoline-5/' CMakeLists.txt
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("lovoalign", :lovoalign)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")
