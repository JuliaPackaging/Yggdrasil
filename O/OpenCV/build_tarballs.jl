# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "OpenCV"
version = v"4.6.0"
version_collapsed_str = replace(string(version), "." => "")

include("../../L/libjulia/common.jl")

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/opencv/opencv.git", "b0dc474160e389b9c9045da5db49d03ae17c6a6b"),
    GitSource("https://github.com/opencv/opencv_contrib.git", "db16caf6ceee76b43b94c846be276e92a43e9700"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Apply patch for BB specific CMake changes
cd opencv_contrib
git apply ../patches/opencv-julia.patch
cd ..

mkdir build && cd build
export USE_QT="ON"

# Patch a minor clang issue
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 -d../opencv ../patches/atomic_fix.patch
fi

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

    # Disable QT
    export USE_QT="OFF"
elif [[ "${target}" == *-w64-* ]]; then
    # Needed for mingw compilation of big files
    export CXXFLAGS="-Wa,-mbig-obj"
    export USE_QT="OFF"
fi

cmake -DCMAKE_FIND_ROOT_PATH=${prefix} \
      -DJulia_PREFIX=${prefix} \
      -DWITH_JULIA=ON \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=11 \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DWITH_QT=${USE_QT} \
      -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
      -DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d,video,gapi,stitching,julia \
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
platforms = vcat(libjulia_platforms.(julia_versions)...)

# We don't have Qt5 for Musl platforms
filter!(p -> libc(p) != "musl", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libopencv_calib3d", "libopencv_calib3d" * version_collapsed_str], :libopencv_calib3d),
    LibraryProduct(["libopencv_objdetect", "libopencv_objdetect" * version_collapsed_str], :libopencv_objdetect),
    LibraryProduct(["libopencv_core", "libopencv_core" * version_collapsed_str], :libopencv_core),
    LibraryProduct(["libopencv_dnn", "libopencv_dnn" * version_collapsed_str], :libopencv_dnn),
    LibraryProduct(["libopencv_imgcodecs", "libopencv_imgcodecs" * version_collapsed_str], :libopencv_imgcodecs),
    LibraryProduct(["libopencv_highgui", "libopencv_highgui" * version_collapsed_str], :libopencv_highgui),
    LibraryProduct(["libopencv_flann", "libopencv_flann" * version_collapsed_str], :libopencv_flann),
    LibraryProduct(["libopencv_gapi", "libopencv_gapi" * version_collapsed_str], :libopencv_gapi),
    LibraryProduct(["libopencv_imgproc", "libopencv_imgproc" * version_collapsed_str], :libopencv_imgproc),
    LibraryProduct(["libopencv_features2d", "libopencv_features2d" * version_collapsed_str], :libopencv_features2d),
    LibraryProduct(["libopencv_stitching", "libopencv_stitching" * version_collapsed_str], :libopencv_stitching),
    LibraryProduct(["libopencv_video", "libopencv_video" * version_collapsed_str], :libopencv_video),
    LibraryProduct(["libopencv_videoio", "libopencv_videoio" * version_collapsed_str], :libopencv_videoio),
    LibraryProduct("libopencv_julia", :libopencv_julia)#,
    # FileProduct("OpenCV.jl.tar", :OpenCV_jl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt5Base_jll", uuid="ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    BuildDependency(PackageSpec(name="libjulia_jll"))
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat="0.11")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
