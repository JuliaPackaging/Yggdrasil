# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XLA"
version = v"0.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openxla/xla.git", "3e0222a9a4f11b5f47ed6c3bcbbdaeee81e2bc68")
]

# Bash recipe for building across all platforms
script = raw"""
apk update
apk add bazel --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
apk add py3-numpy

export TN_NEED_ROCM=0
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0
export TF_CUDA_CLANG=0 
yes "" | ./configure

bazel build --test_output=all --spawn_strategy=local --verbose_failures //xla/...
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")

