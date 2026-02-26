# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenCV"
version = v"4.12.0"
version_collapsed_str = replace(string(version), "." => "")

include("../../L/libjulia/common.jl")

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/opencv/opencv.git", "49486f61fb25722cbcf586b7f4320921d46fb38e"),
    GitSource("https://github.com/barche/opencv_contrib.git","40080954a3afcc331463c2d40c6809de29fde50d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

mkdir build && cd build
export USE_QT="ON"

# Patch a minor clang issue
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 -d../opencv ../patches/atomic_fix.patch
fi

if [[ "${target}" == *-w64-* ]]; then
    # Needed for mingw compilation of big files
    export CXXFLAGS="-Wa,-mbig-obj"
fi

cmake -DCMAKE_FIND_ROOT_PATH=${prefix} \
      -DJulia_PREFIX=${prefix} \
      -DWITH_JULIA=ON \
      -DJulia_FOUND=ON \
      -DHAVE_JULIA=ON \
      -DJulia_WORD_SIZE=${nbits} \
      -DJulia_INCLUDE_DIRS=${includedir}/julia \
      -DJulia_LIBRARY_DIR=${libdir} \
      -DJulia_LIBRARY=${libdir}/libjulia.${dlext} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=11 \
      -DBUILD_TESTS=OFF \
      -DBUILD_PERF_TESTS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DHAVE_CXX_FVISIBILITY_HIDDEN=OFF \
      -DHAVE_CXX_FVISIBILITY_INLINES_HIDDEN=OFF \
      -DWITH_QT=${USE_QT} \
      -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
      -DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d,video,gapi,stitching,julia \
      ../opencv/

make -j${nproc}
make install

# Install also libopencv_julia
cp lib/libopencv_julia.* ${libdir}/.

# Move julia bindings to the prefix
cp -R OpenCV ${prefix}

install_license ../opencv/{LICENSE,COPYRIGHT}
"""


# Newer macOS SDK is needed for recent video codecs
sources, script = require_macos_sdk("12.3", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# Filter out platforms that don't have Qt
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms) # No OpenGL on aarch64 freeBSD
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
filter!(p -> arch(p) != "riscv64", platforms) # No OpenGL on riscv64

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
    Dependency("Qt6Base_jll"; compat="~6.8.2"),
    HostBuildDependency("Qt6Base_jll"),
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29")),
    BuildDependency(PackageSpec(name="libjulia_jll")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat="0.14.7"),
    Dependency("OpenBLAS32_jll"; compat="0.3.24"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = libjulia_julia_compat(julia_versions),
    preferred_gcc_version = v"10")
