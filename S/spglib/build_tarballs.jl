# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "spglib"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/spglib/spglib.git", "12355c77fb7c505a55f52cae36341d73b781a065")
]

# Bash recipe for building across all platforms
script = raw"""
# Needs CMake >= 3.25 provided via HostBuildDependency
apk del cmake

cd $WORKSPACE/srcdir/spglib
args=""
if [[ ! -z "${CMAKE_TARGET_TOOLCHAIN}" ]]; then
  args="${args} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
fi
cmake -B ./build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DSPGLIB_WITH_TESTS=OFF \
      ${args}
cmake --build ./build -j${nproc}
cmake --install ./build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsymspg", :libsymspg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = "3.31.6"))  # Need CMake > 3.25
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"12.1.0")
