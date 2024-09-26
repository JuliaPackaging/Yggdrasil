# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Tasmanian"
version = v"8.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ORNL/TASMANIAN.git", "513b72c6b4d808d459a7416834bfb10ec48d5c92")
    DirectorySource("./bundled") 
]

# Bash recipe for building across all platforms
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/TASMANIAN

# ILP64 patches
#if [[ "${target}" == *x86_64-* ]] ; then
#  atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-add-ILP64-interface-for-Julia-libblass#trampoline.patch
#  cp $WORKSPACE/srcdir/files/tsgJuliaStrampolineWrappers.hpp InterfaceTPL/ 
#fi

mkdir build && cd build
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-lpthread"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTasmanian_ENABLE_RECOMMENDED=ON \
    -DTasmanian_ENABLE_PYTHON=OFF \
    -DBLA_VENDOR="libblastrampoline"\
    -DDEBUG_FIND=ON\
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = supported_platforms()
#platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtasmaniansparsegrid", :libtasmaniansparsegrid),
    LibraryProduct("libtasmaniandream", :libtasmaniandream)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("libblastrampoline_jll"; compat="5.4"),
    HostBuildDependency("CMake_jll"),
]

# License file

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_gcc_version = v"5.2.0")
