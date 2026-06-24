using BinaryBuilder, Pkg

name = "NOMAD"
version = v"4.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bbopt/nomad.git", "d6e2c8c9dbfa275485f5c134198c372adb54f2ad"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/nomad"
mkdir "${WORKSPACE}/path"
export PATH="${WORKSPACE}/path:$PATH}"
export WADF=${WORKSPACE}/srcdir/nomad/src/Attribute/WriteAttributeDefinitionFile.cpp
${CXX_FOR_BUILD} ${WADF} -o ${WORKSPACE}/path/WriteAttributeDefinitionFile

mkdir build
cd build

cmake -DBUILD_INTERFACE_C=ON \
      -DSETSONAME=OFF \
      -DTEST_OPENMP=OFF \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnomadCInterface", :libnomadCInterface),
    LibraryProduct("libnomadAlgos", :libnomadAlgos),
    LibraryProduct("libnomadEval", :libnomadEval),
    LibraryProduct("libnomadUtils", :libnomadUtils),
    LibraryProduct("libsgtelib", :libsgtelib),
    ExecutableProduct("nomad", :nomad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="v1.6")
