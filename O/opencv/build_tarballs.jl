# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "opencv"
version = v"4.5.2"
julia_version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/opencv/opencv.git", "39d25787f16c4dd6435b9fe0a8253394ac51e7fb"),
    GitSource("https://github.com/archit120/opencv_contrib.git", "3178ebf514e9a59e2b673e44c790a987c3c0df73"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build && cd build
if [[ "${target}" == *-apple-* ]]; then
    # We want to use OpenBLAS over Accelerate framework...
    export OpenBLAS_HOME=${prefix}
    export CXXFLAGS=""
    # ...but we also need to rename quite a few symbols
    for symbol in sgemm dgemm cgemm zgemm; do
        # Rename CBLAS symbols for ILP64
        CXXFLAGS="${CXXFLAGS} -Dcblas_${symbol}=cblas_${symbol}64_"
    done
    for symbol in sgesv_ sposv_ spotrf_ sgesdd_ sgeqrf_ sgels_ dgeqrf_ dgesdd_ sgetrf_ dgesv_ dposv_ dgels_ dgetrf_ dpotrf_ dgeev_; do
        # Rename LAPACK symbols for ILP64
        CXXFLAGS="${CXXFLAGS} -D${symbol}=${symbol}64_"
    done
    # Apply patch to help CMake find our 64-bit OpenBLAS
    atomic_patch -p1 -d../opencv ../patches/find-openblas64.patch
fi
cmake -DCMAKE_FIND_ROOT_PATH=${prefix} \
      -DJulia_PREFIX=${prefix} \
      -DWITH_JULIA=ON \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_QT=ON \
      -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
      -DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d,julia \
      ../opencv/
if [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ../patches/freebsd-malloc-h.patch
fi
make -j${nproc}
make install

# Install also libopencv_julia
cp lib/libopencv_julia.* ${libdir}/.
# Move julia bindings to the prefix
cp -R OpenCV ${prefix}

install_license ../opencv/{LICENSE,COPYRIGHT}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# We don't have Qt5 for Musl platforms
filter!(p -> libc(p) != "musl", platforms)

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
    LibraryProduct("libopencv_videoio", :libopencv_videoio),
    LibraryProduct("libopencv_julia", :libopencv_julia)#,
    # FileProduct("OpenCV.jl.tar", :OpenCV_jl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt5Base_jll", uuid="ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
    Dependency(PackageSpec(name="libcxxwrap_julia_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
