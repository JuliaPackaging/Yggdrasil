# Bazel can't deal with `ccache`
ENV["BINARYBUILDER_USE_CCACHE"] = "false"

using BinaryBuilder

name = "XRTServer"
version = v"2018.10.16"

# Collection of sources required
sources = [
    "https://github.com/JuliaComputing/tensorflow.git" =>
    "11b6ca9bc3506443c5b46f42f193ee7ba6fb1f50",
    "https://github.com/bazelbuild/bazel/releases/download/0.17.2/bazel-0.17.2-linux-x86_64" =>
    "674757d40d4ac0f0175df7fe84cd7250cbf67ac7ebac565e905fdc7e24c0fac5",
    "https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux" =>
    "8496c72b16fee61889f9281449b5d633d0b358b46579175c275d85c9205fe953",
    "http://developer.download.nvidia.com/compute/redist/cudnn/v7.1.3/cudnn-9.1-linux-x64-v7.1.tgz" =>
    "dd616d3794167ceb923d706bf73e8d6acdda770751492b921ee6827cdf190228",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tensorflow

# Tensorflow can't search for CuDNN without GNU grep. lol.
apk add grep

# Install CUDA toolkit
mkdir -p $WORKSPACE/tmp
/bin/sh $WORKSPACE/srcdir/cuda_*_linux --silent --tmpdir=$WORKSPACE/tmp --toolkit --toolkitpath=$prefix/cuda

# Install CuDNN
rsync -ra $WORKSPACE/srcdir/cuda/{include,lib64} $prefix/cuda/

# Apply -lrt patch
atomic_patch -p0 $WORKSPACE/srcdir/patches/link_against_librt.patch
chmod +x $WORKSPACE/srcdir/bazel-*
mv $WORKSPACE/srcdir/bazel-* /usr/local/bin/bazel

# Configure to enable CUDA and XLA
export TF_NEED_CUDA=1
export CUDA_TOOLKIT_PATH=$prefix/cuda
export TF_ENABLE_XLA=1
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow/compiler/xrt/utils:xrt_server

# Install to $prefix/bin
mkdir -p $prefix/{bin,lib}
cp bazel-bin/tensorflow/libtensorflow_framework.so $prefix/lib/
cp bazel-bin/tensorflow/compiler/xrt/utils/xrt_server $prefix/bin/
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
