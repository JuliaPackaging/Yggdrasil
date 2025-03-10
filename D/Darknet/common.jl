using BinaryBuilder, Pkg

function gen_common(platforms; openmp = true, gpu = false, kwargs...)
    # "yolov4" https://github.com/AlexeyAB/darknet/releases/tag/yolov4
    version = v"2021.10.29"
    sources = BinaryBuilder.AbstractSource[
        GitSource("https://github.com/AlexeyAB/darknet.git", "9d40b619756be9521bc2ccd81808f502daaa3e9a"),
    ]

    script = "OPENMP=$(Int(openmp))\nGPU=$(Int(gpu))\n" * raw"""
cd $WORKSPACE/srcdir/darknet

if [[ "${GPU}" -eq 1 ]]; then
    ## CUDA setup
    mkdir -p /usr/local
    ln -s "${WORKSPACE}/srcdir/cudnn" /usr/local/cudnn
    ln -s ${prefix}/cuda /usr/local/cuda

    export PATH="/usr/local/cuda/bin:${PATH}"

    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/makefile-fix-cuda-paths.patch"
fi

## Note for the future: Supporting AVX will make more sense with microarchitecture support
# if [[ "${target}" = powerpc64le-* ]] || [[ "${target}" = arm* ]] || [[ "${target}" == aarch* ]] || [[ "${target}" == *-mingw* ]] then
#     # Disable AVX on powerpc, arm, aarch, windows, apple
#     export AVXENABLE=0
# else
#     # Enable everywhere else (linux)
#     export AVXENABLE=1
# fi
export AVXENABLE=0

# Make sure to have the directories, before building
# make obj backup results setchmod
make -j${nproc} \
    libdarknet.${dlext} \
    OPTS="" \
    LIBNAMESO="libdarknet.${dlext}" \
    LIBSO=1 \
    GPU=${GPU} \
    CUDNN=${GPU} \
    CUDNN_HALF=${GPU} \
    OPENCV=0 \
    DEBUG=0 \
    OPENMP=${OPENMP} \
    ZED_CAMERA=0 \
    AVX=${AVXENABLE}

mkdir -p "${libdir}"
cp libdarknet.${dlext} "${libdir}"
install_license LICENSE

rm -rf "${prefix}/cuda"
"""
    # The products that we will ensure are always built
    products = [
        # Do not automatically dlopen the library if depends on CUDA
        LibraryProduct("libdarknet", :libdarknet; dont_dlopen = gpu),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = BinaryBuilder.AbstractDependency[]
    if openmp
        append!(dependencies, [
            # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
            # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
            Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
            Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
        ])
    end

    return version, sources, script, products, dependencies
end
