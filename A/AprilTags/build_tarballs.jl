# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AprilTags"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Affie/apriltags.git", "54d6614284d629e72a391c682c9eb0a2907daa5d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/apriltags/
mkdir build
cd build/

export CFLAGS="-std=gnu99"

cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON_WRAPPER=Off
make -j${nproc}
make install

# Move dll on windows
if [[ ${target} == *-mingw32 ]]; then 
    cp -L *.${dlext} ${libdir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libapriltag", :libapriltag),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
