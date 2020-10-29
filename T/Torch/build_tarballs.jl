# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Torch"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dhairyagandhi96/Torch.jl.git", "85bd08d39e7fba29ec4a643f60dd006ed8be8ede"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu101/libtorch-cxx11-abi-shared-with-deps-1.4.0.zip", "f214bfde532877aa5d4e0803e51a28fa8edd97b6a44b6615f75a70352b6b542e", unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu101/libtorch-win-shared-with-deps-1.4.0.zip", "a18a2fa0d952b56a6b9ddc7aae375847eebb5f1bc02fb24f0c4a1f132f8e45c8", unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/JuliaGPU/CUDABuilder/releases/download/v0.3.0/CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz", "79de5b5085a33bc144b87028e998a1d295a15c3424d6d45b25defe500f616974", unpack_target = "x86_64-linux-gnu/cudnn"),
    ArchiveSource("https://github.com/JuliaGPU/CUDABuilder/releases/download/v0.3.0/CUDNN+CUDA10.1.v7.6.5.x86_64-w64-mingw32.tar.gz", "35f363250ca285315b987561d18871d71ad0403ad92d5259437d5638c3c16d03", unpack_target = "x86_64-w64-mingw32/cudnn"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

mv $target/cudnn $prefix

if [[ ${target} == x86_64-w64-mingw32 ]]; then
    mkdir $prefix/lib
    mv $target/libtorch/bin/* $prefix/bin/
    rm -r $target/libtorch/bin

    EXTRA_CMAKE_FLAGS="-DCMAKE_SYSTEM_NAME=Windows"
fi

mv $target/libtorch/share/* $prefix/share/
mv $target/libtorch/lib/* $prefix/lib/
rm -r $target/libtorch/lib
rm -r $target/libtorch/share
mv $target/libtorch/* $prefix
rm -r $target/libtorch

mkdir -p /usr/local/cuda/lib64
cd /usr/local/cuda/lib64
ln -s ${prefix}/cuda/lib64/libcudart.$dlext libcudart.$dlext
ln -s ${prefix}/cuda/lib64/libnvToolsExt.$dlext libnvToolsExt.$dlext

cd $WORKSPACE/srcdir/Torch.jl/build
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    # FindCUDNN.cmake in Torch.jl is very Linux oriented. Patch it up
    # a little to work in this environment.
    sed -i 's/libcudnn.so/cudnn64_7.dll/g' FindCUDNN.cmake
    sed -i 's/lib"/bin"/g' FindCUDNN.cmake
fi
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$prefix $EXTRA_CMAKE_FLAGS -DTorch_DIR=$prefix/share/cmake/Torch -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda ..
cmake --build .

mkdir -p "${libdir}"
cp -r $WORKSPACE/srcdir/Torch.jl/build/build/*.${dlext} "${libdir}"
rm -rf $prefix/cuda
install_license ${WORKSPACE}/srcdir/Torch.jl/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Temporarily disable Linux build for faster Windows turnaround.
    #Linux(:x86_64, libc=:glibc, compiler_abi = CompilerABI(cxxstring_abi = :cxx11)),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libdoeye_caml", :libdoeye_caml, dont_dlopen = true),
    LibraryProduct("libtorch", :libtorch, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"10.1.243")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
