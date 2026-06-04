using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OpenCV"
version = v"4.13.0"
version_collapsed_str = replace(string(version), "." => "")

include("../../L/libjulia/common.jl")

sources = [
    GitSource("https://github.com/opencv/opencv.git", "fe38fc608f6acb8b68953438a62305d8318f4fcd"),
    GitSource("https://github.com/opencv/opencv_contrib.git", "d99ad2a188210cc35067c2e60076eed7c2442bc3"),  # tag 4.13.0
    # The Julia binding generator now lives in OpenCV.jl (gen/), with the former
    # julia-bindings-upstream-contrib.patch folded in and made reproducible. We
    # overlay it onto opencv_contrib's julia module to build libopencv_julia.
    # Keep this commit's gen/OPENCV_VERSION in lockstep with the OpenCV sources above.
    GitSource("https://github.com/JuliaImages/OpenCV.jl.git", "52c3c7f306891f25027f9db97066909b13f4fffd"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir

# Overlay OpenCV.jl's vendored, reproducible Julia binding generator onto
# opencv_contrib's julia module. This replaces the old in-tree generator and the
# julia-bindings-upstream-contrib.patch (now folded into OpenCV.jl gen/).
rm -rf opencv_contrib/modules/julia/gen
cp -r OpenCV.jl/gen opencv_contrib/modules/julia/gen
cp OpenCV.jl/gen/CMakeLists.txt opencv_contrib/modules/julia/CMakeLists.txt

mkdir build && cd build

# Qt 6.10 requires CMake >= 3.22; use CMake_jll from the host prefix
apk del cmake

if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 -d../opencv ../patches/atomic_fix.patch
fi

atomic_patch -p1 -d../opencv ../patches/vsx_power10_paren.patch

if [[ "${target}" == *-w64-* ]]; then
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
      -DWITH_KLEIDICV=OFF \
      -DWITH_QT=ON \
      -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
      -DBUILD_LIST=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d,video,gapi,stitching,julia \
      ../opencv/

make -j${nproc}
make install

cp lib/libopencv_julia.* ${libdir}/.
# NOTE: the generated Julia wrappers are no longer shipped in the JLL — they live
# in OpenCV.jl (src/generated/). This build only provides libopencv_julia.

install_license ../opencv/{LICENSE,COPYRIGHT}
"""

# Install a recent macOS SDK so AVFoundation (10.13+) and Qt 6.10's
# UniformTypeIdentifiers (11.0+) are available on Intel macOS too. Match
# Qt6Base_jll's SDK/deployment target so the two link cleanly.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "riscv64", platforms)

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
    LibraryProduct("libopencv_julia", :libopencv_julia),
]

dependencies = [
    Dependency("Qt6Base_jll"; compat="~6.10.2"),
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("CMake_jll"),
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29")),
    BuildDependency(PackageSpec(name="libjulia_jll")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat="0.14.7"),
    Dependency("OpenBLAS32_jll"; compat="0.3.24"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = libjulia_julia_compat(julia_versions),
    preferred_gcc_version = v"10")
