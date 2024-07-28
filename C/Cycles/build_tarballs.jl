using BinaryBuilder, Pkg

name = "Cycles"
version = v"4.2.0"  # Adjust this to the version you want to build

# Define the sources where we can download Cycles
sources = [
    GitSource("https://github.com/blender/cycles.git", "6170e50fbd5fb8e36d71676e78c2693e58bf6c3d")
    GitSource("https://github.com/git-lfs/git-lfs.git", "e237bb3a364603cbb92cabc34b8401d1ad5d795b")
]

# Define the build dependencies
dependencies = [
    # Which of the CUDA libraries do we actually need?
    Dependency("CUDA_Driver_jll"),
    Dependency("CUDA_Runtime_jll"),
    Dependency("CUDA_jll"),
    # Which of the AMD ones do we actually need?
    Dependency("HIP_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("hsa_rocr_jll"),
    Dependency("OpenCL_jll"),
    # Which of the oneAPI ones do we actually need?
    Dependency("oneAPI_Support_jll"),
    Dependency("oneAPI_Level_Zero_Loader_jll"),
    Dependency("oneAPI_Level_Zero_Headers_jll"),
    HostBuildDependency(PackageSpec(name="CMake_jll"))
]

# Define the platforms we want to build for
platforms = supported_platforms()

# Define the products that we will get from the build
products = [
    LibraryProduct("libcycles", :libcycles)
    # Add any other products (executables, libraries) that Cycles produces
]

# This is where we define what should happen when we build Cycles
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/git-lfs
go build -o git-lfs
install -Dm755 git-lfs ${bindir}/git-lfs
export HOME=/root
git lfs install

cd $WORKSPACE/srcdir/cycles*
make update
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# Now, let's build it!
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10.2.0", compilers=[:c, :cc, :go])
