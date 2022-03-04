# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Torch"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dhairyagandhi96/Torch.jl.git", "85bd08d39e7fba29ec4a643f60dd006ed8be8ede"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu101/libtorch-cxx11-abi-shared-with-deps-1.4.0.zip", "f214bfde532877aa5d4e0803e51a28fa8edd97b6a44b6615f75a70352b6b542e"),
    ArchiveSource("https://github.com/JuliaGPU/CUDABuilder/releases/download/v0.3.0/CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz", "79de5b5085a33bc144b87028e998a1d295a15c3424d6d45b25defe500f616974", unpack_target = "cudnn"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

mv cudnn $prefix
mv libtorch/share/* $prefix/share/
mv libtorch/lib/* $prefix/lib/
rm -r libtorch/lib
rm -r libtorch/share
mv libtorch/* $prefix
rm -r libtorch

mkdir -p /usr/local/cuda/lib64
cd /usr/local/cuda/lib64
ln -s ${prefix}/cuda/lib64/libcudart.so libcudart.so
ln -s ${prefix}/cuda/lib64/libnvToolsExt.so libnvToolsExt.so

cd $WORKSPACE/srcdir/Torch.jl/build
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$prefix -DTorch_DIR=$prefix/share/cmake/Torch -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda ..
cmake --build .

mkdir -p "${libdir}"
cp -r $WORKSPACE/srcdir/Torch.jl/build/build/*.${dlext} "${libdir}"
rm -rf $prefix/cuda
install_license ${WORKSPACE}/srcdir/Torch.jl/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11"),
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
