# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XLA_Tools"
version = v"2.2.1"  # latest version that doesn't require Bazel 3.x

# Collection of sources required to build tar
sources = [
    ArchiveSource("https://github.com/tensorflow/tensorflow/archive/v$(version).tar.gz",
                  "e6a28e64236d729e598dbeaa02152219e67d0ac94d6ed22438606026a02e0f88"),
]

# Bash recipe for building across all platforms
script = raw"""
cd tensorflow-*
install_license LICENSE

apk update && apk add nss
apk add bazel --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

# our Bazel is v2.2, so sufficient for TF 2.2, but it doesn't realize that.
rm .bazelversion
export TF_IGNORE_MAX_BAZEL_VERSION=1

# the build requires numpy (really), which is only available for python3
apk del python2 # have bazel pick up python3 instead?
ln -s /usr/bin/python3 /usr/bin/python
apk add py3-numpy py3-numpy-dev

export TF_ENABLE_XLA=1
export TF_NEED_JEMALLOC=0
yes "" | ./configure

BAZEL_FLAGS=()
BAZEL_BUILD_FLAGS=()

# don't run out of temporary space
BAZEL_FLAGS+=(--output_user_root=/workspace/bazel_root)

# disable the sandbox and forward environment variables
BAZEL_BUILD_FLAGS+=(--spawn_strategy=local)
while read name; do
    # FIXME: this still doesn't expose the vars to the configure phase, or external projects
    BAZEL_BUILD_FLAGS+=(--action_env=$name)
done <<<"$(compgen -v)"

# start with the 'opt' config
BAZEL_BUILD_FLAGS+=(-c opt)

BAZEL_BUILD_FLAGS+=(--jobs ${nproc})

BAZEL_BUILD_FLAGS+=(--verbose_failures)

bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} \
    //tensorflow/compiler/xla/tools:show_signature \
    //tensorflow/compiler/xla/tools:show_literal \
    //tensorflow/compiler/xla/tools:convert_computation \
    //tensorflow/compiler/xla/tools:show_text_literal \
    //tensorflow/compiler/xla/tools:dumped_computation_to_text \
    //tensorflow/compiler/xla/tools:dumped_computation_to_operation_list

mkdir -p $bindir $libdir
cp bazel-bin/tensorflow/compiler/xla/tools/show_signature \
   bazel-bin/tensorflow/compiler/xla/tools/show_literal \
   bazel-bin/tensorflow/compiler/xla/tools/convert_computation \
   bazel-bin/tensorflow/compiler/xla/tools/show_text_literal \
   bazel-bin/tensorflow/compiler/xla/tools/dumped_computation_to_text \
   bazel-bin/tensorflow/compiler/xla/tools/dumped_computation_to_operation_list \
   $bindir
cp bazel-bin/tensorflow/libtensorflow_framework.so $libdir

# libtensorflow* has super-crazy RPATHs; fix that
for f in $libdir/*.so $bindir/*; do
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../lib64' "${f}"
done
"""

# Only for Linux x64 glibc
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("show_signature", :show_signature),
    ExecutableProduct("show_literal", :show_literal),
    ExecutableProduct("convert_computation", :convert_computation),
    ExecutableProduct("show_text_literal", :show_text_literal),
    ExecutableProduct("dumped_computation_to_text", :dumped_computation_to_text),
    ExecutableProduct("dumped_computation_to_operation_list", :dumped_computation_to_operation_list)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
