# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Faiss"
version = v"1.7.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookresearch/faiss.git", "d87888b13e7eb339bb9c45825e9d20def6665171"),
]

# Bash recipe for building across all platforms
script = raw"""
# Needs CMake >= 3.23.1 provided via HostBuildDependency
apk del cmake

cd faiss

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_PYTHON=OFF \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DFAISS_ENABLE_C_API=ON
cmake --build build --parallel ${nproc}
cmake --install build

install -Dvm 755 build/c_api/libfaiss_c.$dlext $libdir/libfaiss_c.$dlext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms) # musl builds fail - fixed in v1.8.0
filter!(!Sys.isfreebsd, platforms) # freebsd builds fail - fixed in v1.8.0
filter!(!Sys.iswindows, platforms) # Windows builds fail to link: undefined reference to `faiss::OnDiskInvertedListsIOHook::OnDiskInvertedListsIOHook()'

mkl_platforms = Platform[
    Platform("x86_64", "Linux"),
    Platform("i686", "Linux"),
    Platform("x86_64", "MacOS"),
    Platform("x86_64", "Windows"),
]

openblas_platforms = filter(p -> p ∉ mkl_platforms, platforms)

platforms = expand_cxxstring_abis(platforms)
mkl_platforms = expand_cxxstring_abis(mkl_platforms)
openblas_platforms = expand_cxxstring_abis(openblas_platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libfaiss", "faiss"], :libfaiss),
    LibraryProduct(["libfaiss_c", "faiss_c"], :libfaiss_c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
     # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("LAPACK_jll"; platforms = openblas_platforms),
    Dependency("MKL_jll"; platforms = mkl_platforms),
    BuildDependency("MKL_Headers_jll"; platforms = mkl_platforms),
    Dependency("OpenBLAS32_jll"; platforms = openblas_platforms),
    HostBuildDependency(PackageSpec("CMake_jll", v"3.23.3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
