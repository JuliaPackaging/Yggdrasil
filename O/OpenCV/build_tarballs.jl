# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenCV"
version = v"4.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/opencv/opencv/archive/4.4.0.zip", "7faa0991c74cda52313ee37ef73f3e451332a47e7aa36c2bb2240b69f5002d27")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd opencv-4.4.0/
mkdir build
cd build/
cmake ../ -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libopencv_imgcodecs", :libopencv_imgcodecs),
    ExecutableProduct("opencv_visualisation", :opencv_visualisation),
    LibraryProduct("libopencv_video", :libopencv_video),
    ExecutableProduct("opencv_interactive-calibration", :opencv_interactive_calibration),
    ExecutableProduct("opencv_version", :opencv_version),
    LibraryProduct("libopencv_photo", :libopencv_photo),
    LibraryProduct("libopencv_highgui", :libopencv_highgui),
    LibraryProduct("libopencv_calib3d", :libopencv_calib3d),
    LibraryProduct("libopencv_dnn", :libopencv_dnn),
    LibraryProduct("libopencv_flann", :libopencv_flann),
    LibraryProduct("libopencv_imgproc", :libopencv_imgproc),
    LibraryProduct("libopencv_gapi", :libopencv_gapi),
    LibraryProduct("libopencv_ml", :libopencv_ml),
    LibraryProduct("libopencv_videoio", :libopencv_videoio),
    LibraryProduct("libopencv_stitching", :libopencv_stitching),
    LibraryProduct("libopencv_features2d", :libopencv_features2d),
    LibraryProduct("libopencv_objdetect", :libopencv_objdetect),
    LibraryProduct("libopencv_core", :libopencv_core),
    ExecutableProduct("opencv_annotation", :opencv_annotation)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
