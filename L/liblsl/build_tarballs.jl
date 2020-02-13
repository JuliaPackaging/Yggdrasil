# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "liblsl"
version = v"1.13.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://github.com/sccn/liblsl/archive/1.13.0.tar.gz",
    "5b304a5365eba33852da96badfbd9d66556caf4a00c87947a59df2942680a617"),
    DirectorySource("./bundled/patches"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd liblsl-1.13.0

# Add license file
install_license LICENSE

# Link against real time and correct C->C++ library paths on linux
if [[ ${target} == x86_64-linux-* || ${target} == aarch64-linux-* || ${target} == powerpc64le-linux-* ]]; then
    export CXXFLAGS="-lrt"
    export CFLAGS="-lrt -Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

if [[ ${target} == i686-linux-* || ${target} == arm-linux-* ]]; then
    export CXXFLAGS="-lrt"
    export CFLAGS="-lrt -Wl,-rpath-link,/opt/${target}/${target}/lib"
fi

# Enable C++ 2011 support and patch for MinGW
if [[ ${target} == *-w64-* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/liblsl_mingw.diff
    # Line endings are confused on the test internal CMakeLists, fix them before patch
    dos2unix testing/CMakeLists.txt
    atomic_patch -p1 $WORKSPACE/srcdir/lsl_test_internal_mingw.diff
    export CXXFLAGS="-std=c++11"
fi

mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLSL_UNIXFOLDERS=1 -DLSL_NO_FANCY_LIBNAME=1 -DLSL_UNITTESTS=1 ../
make -j${nproc}

# We can't run unit-tests as we are cross-compiling
#./lslver
#./testing/lsl_test_internal 
#./testing/lsl_test_exported 

make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblsl", :liblsl),
    ExecutableProduct("lslver", :lslver)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
