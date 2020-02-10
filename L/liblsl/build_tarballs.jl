# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "liblsl"
version = v"1.13.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/sccn/liblsl/archive/1.13.0.tar.gz" =>
    "5b304a5365eba33852da96badfbd9d66556caf4a00c87947a59df2942680a617",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd liblsl-1.13.0
mkdir build
cd build

if [[ ${target} == x86_64-linux-* ]]; then
    export CXXFLAGS="-lrt"
    export CFLAGS="-lrt -Wl,-rpath-link,/opt/${target}/${target}/lib64"
else
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLSL_UNIXFOLDERS=1 -DLSL_NO_FANCY_LIBNAME=1 -DLSL_UNITTESTS=1 ../
make
./lslver
./testing/lsl_test_internal 
./testing/lsl_test_exported 
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [
#    Linux(:x86_64, libc=:musl),
#    Linux(:x86_64, libc=:glibc),
#    Linux(:aarch64, libc=:glibc)
#]
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblsl", :liblsl),
    ExecutableProduct("lslver", :lslver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
