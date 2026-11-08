using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "L", "libjulia", "common.jl"))

version = v"4.14.0"
version_collapsed_str = replace(string(version), "." => "")

sources = [
    GitSource("https://github.com/opencv/opencv.git", "0654a42e19215ef25b1d367d822f3c630447e7c7"; tag="$(version)"),
    GitSource("https://github.com/opencv/opencv_contrib.git", "a8e9acd62cabd30419dba83007f2ac0d07de5e2c"; tag="$(version)"),
    # The Julia binding generator lives in OpenCV.jl (gen/); it is overlaid onto
    # opencv_contrib's julia module. Keep its gen/OPENCV_VERSION in lockstep with the sources above.
    GitSource("https://github.com/JuliaImages/OpenCV.jl.git", "244e22cb06b1d890ce4beb9fec3a5f7993957fac"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir

rm -rv opencv_contrib/modules/julia/gen
cp -rv OpenCV.jl/gen opencv_contrib/modules/julia/gen
cp -v OpenCV.jl/gen/CMakeLists.txt opencv_contrib/modules/julia/CMakeLists.txt

# Qt 6.10 requires CMake >= 3.22; use CMake_jll from the host prefix
apk del cmake

if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 -d opencv patches/atomic_fix.patch
fi

if [[ "${target}" == *-w64-* ]]; then
    export CXXFLAGS="-Wa,-mbig-obj"
fi

build_list=core,imgproc,imgcodecs,highgui,videoio,dnn,features2d,objdetect,calib3d,video,gapi,stitching,julia
cmake_args=()

if [[ "${bb_full_target}" == *cuda+* ]]; then
    # BinaryBuilder's x86_64 host needs x86_64 CUDA tools, paired with the target C++ compiler.
    if [[ "${target}" == aarch64-* ]]; then
        export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
        export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
        rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
        cp -a cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
        cp -a libnvvm-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
    fi

    mkdir -pv ${WORKSPACE}/tmpdir
    export TMPDIR=${WORKSPACE}/tmpdir

    # core refuses to configure with CUDA unless opencv_contrib's cudev is built.
    build_list+=,cudev
    # nvcc searches lib64; the SDK uses lib. Vendor libraries require newer glibc symbols.
    # Keep PTX for the newest architecture so newer GPUs can JIT.
    cmake_args+=(
        -DWITH_CUDA=ON
        -DWITH_CUDNN=ON
        -DOPENCV_DNN_CUDA=ON
        -DENABLE_CUDA_FIRST_CLASS_LANGUAGE=ON
        -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc
        -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined"
        -DCUDAToolkit_ROOT=${prefix}/cuda
        -DCMAKE_CUDA_ARCHITECTURES="75-real;80-real;86-real;89-real;90-real;100-real;120"
    )
fi

cmake -B build \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
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
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DHAVE_CXX_FVISIBILITY_HIDDEN=OFF \
    -DHAVE_CXX_FVISIBILITY_INLINES_HIDDEN=OFF \
    -DWITH_KLEIDICV=OFF \
    -DWITH_QT=ON \
    -DOPENCV_EXTRA_MODULES_PATH=${WORKSPACE}/srcdir/opencv_contrib/modules \
    -DBUILD_LIST=${build_list} \
    "${cmake_args[@]}" \
    opencv
cmake --build build --parallel ${nproc}
cmake --install build

cp -v build/lib/libopencv_julia.* ${libdir}

# Modified SDK files would otherwise be packaged.
if [[ "${bb_full_target}" == *cuda+* ]] && [[ "${target}" == aarch64-* ]]; then
    rm -rfv ${prefix}/cuda
fi

install_license opencv/{LICENSE,COPYRIGHT}
"""

# Install a recent macOS SDK so AVFoundation (10.13+) and Qt 6.10's
# UniformTypeIdentifiers (11.0+) are available on Intel macOS too. Match
# Qt6Base_jll's SDK/deployment target so the two link cleanly.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

products = [
    [LibraryProduct(["libopencv_$(m)", "libopencv_$(m)$(version_collapsed_str)"], Symbol("libopencv_$(m)"))
     for m in ("calib3d", "objdetect", "core", "dnn", "imgcodecs", "highgui", "flann", "gapi",
               "imgproc", "features2d", "stitching", "video", "videoio")];
    LibraryProduct("libopencv_julia", :libopencv_julia)
]

dependencies = [
    Dependency("Qt6Base_jll"; compat="~6.10.2"),
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("CMake_jll"),
    Dependency("Libglvnd_jll"; compat="1.7.0"),
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7"),
    Dependency("OpenBLAS32_jll"; compat="0.3.24"),
]
