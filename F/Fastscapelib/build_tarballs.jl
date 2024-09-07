# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Fastscapelib"
version = v"2.8.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fastscape-lem/fastscapelib-fortran.git", "b4d13f4703c0d682b38c513c6754f0d0813c076f")
]

# Bash recipe for building across all platforms
script = raw"""

# so we can use a newer version of cmake
apk del cmake

cd $WORKSPACE/srcdir/fastscapelib-fortran/

# Configure
cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DBUILD_FASTSCAPELIB_SHARED=ON  \
    -DBUILD_FASTSCAPELIB_STATIC=OFF

# Compile
cmake --build build --parallel ${nproc}

# Deploy 
install -Dvm 755 "build/libfastscapelib_fortran.${dlext}" -t "${libdir}"

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfastscapelib_fortran", :libfastscapelib_fortran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    
        BuildDependency("LLVMCompilerRT_jll"; platforms=[Platform("aarch64", "macos")]),
        HostBuildDependency(PackageSpec(; name="CMake_jll"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    julia_compat="1.9",
    preferred_gcc_version = v"9")
