# Bazel can't deal with `ccache`
ENV["BINARYBUILDER_USE_CCACHE"] = "false"

using BinaryBuilder

name = "XRTServer_lite"
version = v"2018.11.01"

# Collection of sources required
sources = [
    "https://github.com/JuliaComputing/tensorflow.git" =>
    "36c34bd2d744f0027c24e3afae118b5d956ce741",
    "https://github.com/bazelbuild/bazel/releases/download/0.17.2/bazel-0.17.2-linux-x86_64" =>
    "674757d40d4ac0f0175df7fe84cd7250cbf67ac7ebac565e905fdc7e24c0fac5",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
# bazel always looks for `ar` in `/usr/bin/ar`
ln -sf "$AR" /usr/bin/ar

# Apply -lrt patch
cd $WORKSPACE/srcdir/tensorflow
atomic_patch -p0 $WORKSPACE/srcdir/patches/link_against_librt.patch

# Apply XRT patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/xrt.patch

# Apply pending TF patches
atomic_patch -p1 $WORKSPACE/srcdir/patches/window_reversal.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/parallel_conditionals.patch

# Get `bazel` onto our $PATH
chmod +x $WORKSPACE/srcdir/bazel-*
mv $WORKSPACE/srcdir/bazel-* $WORKSPACE/srcdir/bazel
export PATH=$PATH:$WORKSPACE/srcdir
export TMPDIR=$WORKSPACE/tmp
mkdir -p $TMPDIR

# Configure to enable CUDA and XLA, disable jemalloc
export TF_ENABLE_XLA=1
export TF_NEED_JEMALLOC=0
yes "" | ./configure

# Do the actual build for our tools
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow:libtensorflow.so
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow/compiler/xrt/utils:xrt_server
bazel --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow/compiler/xla/tools:dumped_computation_to_text

# Install to $prefix/bin
mkdir -p $prefix/{bin,lib}
cp bazel-bin/tensorflow/libtensorflow.so $prefix/lib/
cp bazel-bin/tensorflow/libtensorflow_framework.so $prefix/lib/
cp bazel-bin/tensorflow/compiler/xrt/utils/xrt_server $prefix/bin/
cp bazel-bin/tensorflow/compiler/xla/tools/dumped_computation_to_text $prefix/bin/

# libtensorflow* has super-crazy RPATHs; fix that
for f in ${prefix}/lib/libtensorflow* ${prefix}/bin/*; do
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../lib64' "${f}"
done
"""

# We attempt to build for only x86_64-linux-gnu
platforms = [Linux(:x86_64)]

products(prefix) = [
    ExecutableProduct(prefix, "xrt_server", :xrt_server),
    ExecutableProduct(prefix, "dumped_computation_to_text", :dumped_computation_to_text),
]

dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.2/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
