# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AWSLC"
version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-lc.git", "11b50d39cf2378703a4ca6b6fee9d76a2e9852d1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-lc

# Disable -Werror because there are... well... warnings
sed -i 's/-Werror//g' CMakeLists.txt

if [[ "${target}" == *-mingw* ]]; then
    # GetTickCount64 requires Windows Vista:
    # https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount64
    export CXXFLAGS=-D_WIN32_WINNT=0x0600
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STATIC_LIBS=OFF \
    -DBUILD_SHARED_LIBS=ON -GNinja \
    ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcrypto", :libcrypto),
    LibraryProduct("libssl", :libssl),
    LibraryProduct("libdecrepit", :libdecrepit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TODO: this is needed only for Windows, but it looks like filtering
    # platforms for `HostBuildDependency` is broken
    HostBuildDependency("NASM_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
