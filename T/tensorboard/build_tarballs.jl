# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tensorboard"
version = v"2.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tensorflow/tensorboard.git", "29cfcec9d15c47d1bf54b15df24e65bc38c188e6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tensorboard/

install_license LICENSE
/sbin/apk update 
apk add nss
apk add bazel3 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
apk add py3-numpy py3-numpy-dev
apk add python3-dev # so it can find `Python.h`

export PYTHON_BIN_PATH=/usr/bin/python3

# don't run out of temporary space
export YARN_CACHE_FOLDER=/workspace/yarn_cache

BAZEL_FLAGS=()

# don't run out of temporary space
BAZEL_FLAGS+=(--output_user_root=/workspace/bazel_root)

BAZEL_BUILD_FLAGS=()

# try to pass the right commands so it can find `libstdc++`
# note: doesn't seem to work
BAZEL_BUILD_FLAGS+=(--linkopt="-L${libdir}")
export LDFLAGS="-L${libdir}"
BAZEL_BUILD_FLAGS+=(--action_env=LD_LIBRARY_PATH)

echo "LDFLAGS=$LDFLAGS"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

# disable the sandbox and forward environment variables
BAZEL_BUILD_FLAGS+=(--spawn_strategy=local)
while read name; do
    BAZEL_BUILD_FLAGS+=(--action_env=$name)
done <<<"$(compgen -v)"

# start with the 'opt' config
BAZEL_BUILD_FLAGS+=(-c opt)
BAZEL_BUILD_FLAGS+=(--jobs ${nproc})
BAZEL_BUILD_FLAGS+=(--verbose_failures)

echo "========================================="
printf '%s\n' "${BAZEL_FLAGS[@]}"
echo "========================================="
printf '%s\n' "${BAZEL_BUILD_FLAGS[@]}"
echo "========================================="


bazel ${BAZEL_FLAGS[@]} build ${BAZEL_BUILD_FLAGS[@]} tensorboard:tensorboard
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
]

platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = Product[# not sure yet
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"6")
