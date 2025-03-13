# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_common"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-common.git", "7fb0071ab88182bffcc18a4a09bdb4dd2a5751d8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-common

mkdir build && cd build
if [[ "${target}" =~ "mingw" ]]; then
   # Require Windows 7
   export CFLAGS="-D_WIN32_WINNT=0x0601"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DBUILD_TESTING=OFF \
	-DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
	..
cmake --build . -j${nproc} --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Disable 32-bit windows because it's too much for the time being:
# <https://github.com/awslabs/aws-c-common/pull/1059#issuecomment-1716300945>.
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaws-c-common", :libaws_c_common),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
