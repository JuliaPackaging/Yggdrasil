using BinaryBuilder, Pkg

function gen_common(rest...; openmp = true, gpu = false, kwargs...)
    version = v"2020.6.5"
    sources = BinaryBuilder.AbstractSource[
        ArchiveSource("https://github.com/AlexeyAB/darknet/archive/3708b2e47d355ba0a206fd7a06bbc5a6e38af4ff.zip", "e18a6374822fe3c9b95f2b6a4086decbdfbd1c589f2481ce5704a4384044ea6f")
    ]

    script = "OPENMP=$(Int(openmp))\nGPU=$(Int(gpu))\n" * raw"""
cd $WORKSPACE/srcdir/darknet-*

if [[ "${GPU}" -eq 1 ]]; then
    ## CUDA setup
    mkdir -p /usr/local
    ln -s "${WORKSPACE}/srcdir/cudnn" /usr/local/cudnn
    ln -s ${prefix}/cuda /usr/local/cuda

    export PATH="/usr/local/cuda/bin:${PATH}"

    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/makefile-fix-cuda-paths.patch"
fi

## Required for OPENMP=1
if [[ ${OPENMP} -eq 1 ]] && ([[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]); then
    CC=gcc
    CXX=g++
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
        push!(dependencies, Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")))
    end

    return version, sources, script, products, dependencies
end
