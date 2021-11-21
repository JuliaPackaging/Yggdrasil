# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cilantro"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kzampog/cilantro.git", "d7e654be0deb262aa50773793a0080652c79e473")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cilantro/

mkdir build && cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON \
-DBUILD_EXAMPLES=OFF \
-DENABLE_NATIVE_BUILD_OPTIMIZATIONS=OFF \
-DENABLE_NON_DETERMINISTIC_PARALLELISM=OFF

make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
#cmake install only grabs the .dll.a and leaves the actual .dll behind, manually move it 
mv *.dll ${libdir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

 platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libcilantro", :libcilantro)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#uses CXX17 cmake standard, 5 seems to be lowest version number I can get to compile
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")
