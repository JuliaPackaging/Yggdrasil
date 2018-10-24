# Bazel can't deal with `ccache`
ENV["BINARYBUILDER_USE_CCACHE"] = "false"

using BinaryBuilder

name = "XRTServer"
version = v"2018.10.23"

# Collection of sources required
sources = [
    "https://github.com/JuliaComputing/tensorflow.git" =>
    "36c34bd2d744f0027c24e3afae118b5d956ce741",
    "https://github.com/bazelbuild/bazel/releases/download/0.17.2/bazel-0.17.2-linux-x86_64" =>
    "674757d40d4ac0f0175df7fe84cd7250cbf67ac7ebac565e905fdc7e24c0fac5",

    # CuDAAAAAA
    "http://us.download.nvidia.com/XFree86/Linux-x86_64/410.66/NVIDIA-Linux-x86_64-410.66.run" =>
    "8fb6ad857fa9a93307adf3f44f5decddd0bf8587a7ad66c6bfb33e07e4feb217",
    "https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux" =>
    "8496c72b16fee61889f9281449b5d633d0b358b46579175c275d85c9205fe953",
    "http://developer.download.nvidia.com/compute/redist/cudnn/v7.1.3/cudnn-9.1-linux-x64-v7.1.tgz" =>
    "dd616d3794167ceb923d706bf73e8d6acdda770751492b921ee6827cdf190228",
    "https://github.com/NVIDIA/nccl.git" =>
    "f93fe9bfd94884cec2ba711897222e0df5569a53",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
# Tensorflow can't search for CuDNN without GNU grep. lol.
apk add grep

# bazel always looks for `ar` in `/usr/bin/ar`
ln -sf "$AR" /usr/bin/ar


# Install CUDA driver libraries
mkdir -p ${prefix}/lib
chmod +x NVIDIA-Linux-x86_64-*.run
./NVIDIA-Linux-x86_64-*.run -x
cp NVIDIA-Linux-x86_64-*/libcuda.so.* $prefix/lib/libcuda.so.1
cp NVIDIA-Linux-x86_64-*/libnvidia-fatbinaryloader.so.* $prefix/lib/

# Install CUDA toolkit
mkdir -p $WORKSPACE/tmp
/bin/sh $WORKSPACE/srcdir/cuda_*_linux --silent --tmpdir=$WORKSPACE/tmp --toolkit --toolkitpath=$prefix

# Install CuDNN
rsync -ra $WORKSPACE/srcdir/cuda/{include,lib64} $prefix

# Install Nickel
cd $WORKSPACE/srcdir/nccl
mkdir -p ${prefix}/{include,lib}
make -j${nproc} src.build CUDA_HOME=$prefix
mv build/include/* $prefix/include/
mv build/lib/* $prefix/lib/

# Apply -lrt patch
cd $WORKSPACE/srcdir/tensorflow
atomic_patch -p0 $WORKSPACE/srcdir/patches/link_against_librt.patch

# Apply XRT patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/xrt.patch

# Get `bazel` onto our $PATH
chmod +x $WORKSPACE/srcdir/bazel-*
mv $WORKSPACE/srcdir/bazel-* $WORKSPACE/srcdir/bazel
export PATH=$PATH:$WORKSPACE/srcdir

# Configure to enable CUDA and XLA, disable jemalloc
export TF_NEED_CUDA=1
export TF_CUDA_VERSION=9.1
export CUDA_TOOLKIT_PATH=$prefix
export CUDNN_INSTALL_PATH=$prefix
export TF_ENABLE_XLA=1
export TF_NEED_JEMALLOC=0
yes "" | ./configure

# Do the actual build for both xrt_server and libtensorflow.so
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow:libtensorflow.so
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow/compiler/xrt/utils:xrt_server

# Install to $prefix/bin
mkdir -p $prefix/{bin,lib}
cp bazel-bin/tensorflow/libtensorflow.so $prefix/lib/
cp bazel-bin/tensorflow/libtensorflow_framework.so $prefix/lib/
cp bazel-bin/tensorflow/compiler/xrt/utils/xrt_server $prefix/bin/

# Cleanup things we don't need
rm -rf ${prefix}/{doc,jre,samples,nsight,nsightee_plugins,libnvvp,libnsight}
rm -f ${prefix}/lib64/*.a
rm -f ${prefix}/lib/*.a
"""

# We attempt to build for only x86_64-linux-gnu
platforms = [Linux(:x86_64)]

products(prefix) = [
    ExecutableProduct(prefix, "xrtserver", :xrtserver),
]

dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.2/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
