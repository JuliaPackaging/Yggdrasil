using BinaryBuilder, Pkg

name = "Libxc"
version = v"7.1.2"
include("../sources.jl")


# Bash recipe for building across all platforms
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
#   - Libxc >= 7.1 requires CMake >= 3.21, so CMake_jll is used instead of the base image CMake
script = raw"""
# Use CMake_jll instead of the base image CMake
apk del cmake

cd $WORKSPACE/srcdir/libxc-*/

# Libxc >= 7.1 needs calls backtrace(), which lives in libexecinfo on FreeBSD
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="${LDFLAGS} -lexecinfo"
fi

mkdir libxc_build
cd libxc_build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      -DENABLE_FORTRAN=ON \
      -DMAXORDER=2 ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = remove_unsupported_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
    LibraryProduct("libxcf03", :libxcf03)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8",
               julia_compat="1.8")
