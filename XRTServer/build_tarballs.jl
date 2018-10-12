# Bazel can't deal with `ccache`
ENV["BINARYBUILDER_USE_CCACHE"] = "false"

using BinaryBuilder

name = "XRTServer"
version = v"2018.09.26"

# Collection of sources required
sources = [
    "https://github.com/JuliaComputing/tensorflow.git" =>
    "11b6ca9bc3506443c5b46f42f193ee7ba6fb1f50",
    "https://github.com/bazelbuild/bazel/releases/download/0.17.2/bazel-0.17.2-linux-x86_64" =>
    "674757d40d4ac0f0175df7fe84cd7250cbf67ac7ebac565e905fdc7e24c0fac5",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tensorflow

# Apply -lrt patch
atomic_patch -p0 $WORKSPACE/srcdir/patches/link_against_librt.patch

chmod +x $WORKSPACE/srcdir/bazel-*
$WORKSPACE/srcdir/bazel-* --output_user_root=/workspace/bazel_root build -c opt --verbose_failures //tensorflow/compiler/xrt/utils:xrt_server

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
