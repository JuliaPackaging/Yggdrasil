using BinaryBuilder

name = "Bazel"
version = v"8.3.1"
sources = [
    ArchiveSource("https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_alpine-linux_hotspot_21.0.7_6.tar.gz", "79ecc4b213d21ae5c389bea13c6ed23ca4804a45b7b076983356c28105580013"),
    ArchiveSource("https://github.com/bazelbuild/bazel/releases/download/$(version)/bazel-$(version)-dist.zip", "79da863df05fa4de79a82c4f9d4e710766f040bc519fd8b184a4d4d51345d5ba"),

]

script = raw"""
# Enter the funzone
export JAVA_HOME="`pwd`/jdk-21.0.7+6"

export BAZEL_CXXOPTS="-std=c++17"
mkdir .tmp
export TMPDIR=`pwd`/.tmp
export TMP=$TMPDIR
export TEMP=$TMPDIR

# Set the default verbose mode in buildenv.sh so that we do not display command
# output unless there is a failure.  We do this conditionally to offer the user
# a chance of overriding this in case they want to do so.
: ${VERBOSE:=no}

source scripts/bootstrap/buildenv.sh

mkdir -p output
: ${BAZEL:=}

#
# Create an initial binary so we can host ourself
#
if [ ! -x "${BAZEL}" ]; then
  new_step 'Building Bazel from scratch'
  source scripts/bootstrap/compile.sh
fi

#
# Bootstrap bazel using the previous bazel binary = release binary
#
if [ "${EMBED_LABEL-x}" = "x" ]; then
  # Add a default label when unspecified
  git_sha1=$(git_sha1)
  EMBED_LABEL="$(get_last_version) (@${git_sha1:-non-git})"
fi

export EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs ${nproc}"
set -o xtrace

source scripts/bootstrap/bootstrap.sh

bazel_build "src:bazel_nojdk${EXE_EXT}" \
  --action_env=PATH \
  --host_platform=@platforms//host \
  --platforms=@platforms//host \
  --action_env=USE_CCACHE \
  --action_env=CCACHE_DIR \
  --action_env=CCACHE_NOHASHDIR=yes

bazel_bin_path="$(get_bazel_bin_path)/src/bazel_nojdk${EXE_EXT}"
cp -f "$bazel_bin_path" "output/bazel${EXE_EXT}"
chmod 0755 "output/bazel${EXE_EXT}"
BAZEL="$(pwd)/output/bazel${EXE_EXT}"

install -Dvm 755 ${BAZEL} "${bindir}/bazel"
install_license LICENSE
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("bazel", :bazel),
]

dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
