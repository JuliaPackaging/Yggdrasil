# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "opencv"
version = v"4.5.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/opencv/opencv.git", "39d25787f16c4dd6435b9fe0a8253394ac51e7fb"),
    GitSource("https://github.com/opencv/opencv_contrib.git", "790d83c50ef8b1db0d6994504d02911dfbba5fcb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build
cmake -DCMAKE_FIND_ROOT_PATH=$prefix       -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}       -DCMAKE_BUILD_TYPE=Release       -DWITH_QT=ON   -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules   -DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d       ../opencv/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libopencv_calib3d", :libopencv_calib3d),
    LibraryProduct("libopencv_objdetect", :libopencv_objdetect),
    LibraryProduct("libopencv_core", :libopencv_core),
    LibraryProduct("libopencv_dnn", :libopencv_dnn),
    LibraryProduct("libopencv_imgcodecs", :libopencv_imgcodecs),
    LibraryProduct("libopencv_highgui", :libopencv_highgui),
    LibraryProduct("libopencv_flann", :libopencv_flann),
    LibraryProduct("libopencv_imgproc", :libopencv_imgproc),
    LibraryProduct("libopencv_features2d", :libopencv_features2d),
    LibraryProduct("libopencv_videoio", :libopencv_videoio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
