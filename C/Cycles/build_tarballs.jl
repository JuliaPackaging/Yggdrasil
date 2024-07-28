using BinaryBuilder, Pkg

name = "Cycles"
version = v"4.2.0"  # Adjust this to the version you want to build

# Define the sources where we can download Cycles
sources = [
    GitSource("https://github.com/blender/cycles.git", "6170e50fbd5fb8e36d71676e78c2693e58bf6c3d"),
    GitSource("https://github.com/git-lfs/git-lfs.git", "e237bb3a364603cbb92cabc34b8401d1ad5d795b")
]

# Define the build dependencies
dependencies = [
    Dependency("OpenImageIO_jll"),
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
    Dependency("oneTBB_jll"),
    Dependency("oneAPI_Support_jll"),
    Dependency("oneAPI_Level_Zero_Loader_jll"),
    Dependency("oneAPI_Level_Zero_Headers_jll"),
    Dependency("Xorg_libSM_jll"),
    Dependency("boost_jll"),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version=v"3.29.3+1"))
]

# Define the platforms we want to build for
platforms = platforms = [
    Platform("x86_64", "linux", libc="glibc"),
    # Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),
    # Platform("x86_64", "windows")
]

# Define the products that we will get from the build
products = [
    # for testing purposes we'll ship the cycles standalone
    # But won't be very usable going forward
    ExecutableProduct("cycles", :cycles),
    LibraryProduct("libcycles", :libcycles),
    LibraryProduct("libcycles_device", :libcycles_device),
    LibraryProduct("libcycles_graph", :libcycles_graph),
    LibraryProduct("libcycles_hydra", :libcycles_hydra),
    LibraryProduct("libcycles_integrator", :libcycles_integrator),
    LibraryProduct("libcycles_kernel", :libcycles_kernel),
    LibraryProduct("libcycles_kernel_osl", :libcycles_kernel_osl),
    LibraryProduct("libcycles_scene", :libcycles_scene),
    LibraryProduct("libcycles_session", :libcycles_session),
    LibraryProduct("libcycles_subd", :libcycles_subd),
    LibraryProduct("libcycles_util", :libcycles_util),
    LibraryProduct("libextern_cuew", :libextern_cuew),
    LibraryProduct("libextern_hipew", :libextern_hipew),
    LibraryProduct("libextern_libc_compat", :libextern_libc_compat),
    LibraryProduct("libextern_sky", :libextern_sky)
]
raw"""
apk del cmake
cd $WORKSPACE/srcdir/git-lfs
go build -o git-lfs
install -Dm755 git-lfs ${bindir}/git-lfs
export HOME=/root
git lfs install

cd $WORKSPACE/srcdir/cycles
make update
"""
# This is where we define what should happen when we build Cycles
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/git-lfs
go build -o git-lfs
install -Dm755 git-lfs ${bindir}/git-lfs
export HOME=/root
git lfs install
apk del cmake
cd $WORKSPACE/srcdir/cycles
make update
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_CYCLES_OSL=OFF \
    -DWITH_CYCLES_HYDRA_RENDER_DELEGATE=OFF \
    -DWITH_CYCLES_USD=OFF \
    -DWITH_CYCLES_EMBREE=OFF \
    -DWITH_CYCLES_OPENCOLORIO=OFF \
    -DWITH_CYCLES_ALEMBIC=OFF \
    -DWITH_CYCLES_OSL=OFF

cmake --build build --parallel ${nproc}
cmake --install build
"""

# Now, let's build it!
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10.2.0", allow_unsafe_flags=true, compilers=[:c, :cc, :go])
