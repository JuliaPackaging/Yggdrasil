using BinaryBuilder

name = "Bazel"
version = v"7.6.1"
sources = [
    ArchiveSource("https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_alpine-linux_hotspot_21.0.7_6.tar.gz", "79ecc4b213d21ae5c389bea13c6ed23ca4804a45b7b076983356c28105580013"),
    ArchiveSource("https://github.com/bazelbuild/bazel/releases/download/7.6.1/bazel-7.6.1-dist.zip", "c1106db93eb8a719a6e2e1e9327f41b003b6d7f7e9d04f206057990775a7760e"),
    
]

script = raw"""
# Enter the funzone
export JAVA_HOME="`pwd`/jdk-21.0.7+6"

env JAVA_HOME=$JAVA_HOME EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs ${nproc}" ./compile.sh

install -Dvm 755 bazel-bin/src/bazel-dev "${bindir}/bazel"
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
]

products = [
    ExecutableProduct("bazel", :bazel),
]

dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
