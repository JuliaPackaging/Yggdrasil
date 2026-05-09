# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Btop"
version = v"1.4.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/aristocratos/btop.git", "6e39144aaf5a6bc01b9f795010b0914431067183"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/btop*

# The function `get_xdg_state_dir` calls `getenv` and is thus not constexpr
sed -i -e 's/static constexpr auto get_xdg_state_dir/static auto get_xdg_state_dir/' src/btop_config.cpp

FLAGS=(
    THREADS=${nproc}
    CC="$CC -Wno-implicit-function-declaration"   # CFLAGS is not used when building
    PREFIX=${prefix}
)

# Set platform and architecture flags manually;
# otherwise, the build system runs `uname`, which does not work since we cross-build.
if [[ "${target}" == *-linux* ]]; then
    FLAGS+=(PLATFORM=Linux)
elif [[ "${target}" == *-darwin* ]]; then
    FLAGS+=(PLATFORM=MacOS)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(PLATFORM=FreeBSD)
fi
if [[ "${target}" == x86_64-* ]]; then
    FLAGS+=(ARCH=x86_64)
elif [[ "${target}" == aarch64-* ]]; then
    FLAGS+=(ARCH=arm64)
elif [[ "${target}" == riscv64-* ]]; then
    FLAGS+=(ARCH=riscv64)
else
    FLAGS+=(ARCH=other)
fi

if [[ "${target}" == x86_64-linux-gnu ]]; then
    # Enable GPU also on aarch64, this needs to explicitly link to libdl for `dlerror` symbol.
    FLAGS+=(GPU_SUPPORT=true ADDFLAGS="-ldl")
else
    # We cannot enable GPU support on non-Intel systems.
    # The build system would try to build the Intel GPU support code unconditionally.
    # (Some parts of the build system honour `INTEL_GPU_SUPPORT`, but others don't.)
    FLAGS+=(GPU_SUPPORT=false ADDFLAGS="")
fi

echo "${FLAGS[@]}"
make -j${nproc} "${FLAGS[@]}"
make install "${FLAGS[@]}"   # PREFIX=${prefix}
"""

sources, script = require_macos_sdk("14.5", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows))

# The products that we will ensure are always built
products = [
    ExecutableProduct("btop", :btop)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"14")
