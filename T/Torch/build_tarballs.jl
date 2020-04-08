# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Torch"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dhairyagandhi96/Torch.jl.git", "985c4280c17fd9b0af978760be66761456a0113b"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu101/libtorch-cxx11-abi-shared-with-deps-1.4.0.zip", "f214bfde532877aa5d4e0803e51a28fa8edd97b6a44b6615f75a70352b6b542e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv libtorch/ ${prefix}
cd /usr/local/
mkdir cuda
cd cuda
mkdir lib64
cd lib64/
ln -s ${prefix}/lib64/libcudart.so libcudart.so
ln -s ${prefix}/lib64/libnvToolsExt.so libnvToolsExt.so
cd ${prefix}
mkdir cudnn && cd cudnn
wget https://github.com/JuliaGPU/CUDABuilder/releases/download/v0.3.0/CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz
tar -xvf CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz 
rm CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz 
cd $WORKSPACE/srcdir/Torch.jl/build
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$prefix -DTorch_DIR=$prefix/libtorch/share/cmake/Torch -DCUDA_TOOLKIT_ROOT_DIR=$prefix -DCUDNN_LIBRARY_PATH=$prefix/cudnn/lib/libcudnn.so  -DCUDNN_INCLUDE_DIR=$prefix/cudnn/include ..
cmake --build .
mkdir -p "${libdir}"
cp -r $WORKSPACE/srcdir/Torch.jl/build/build/* "${libdir}"
cp $WORKSPACE/srcdir/Torch.jl/build/*.cpp $WORKSPACE/srcdir/Torch.jl/build/*.h "${prefix}/include"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libdoeye_caml", :libdoeye_caml, dont_dlopen = true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"10.1.243", uuid="4f82f1eb-248c-5f56-a42e-99106d144614"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
