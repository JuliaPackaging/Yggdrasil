using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# TODO: Ship nvToolsExt.h with NVTX_jll and use here instead of patching it out

name = "AMGX"
version = v"2.4.0"
sources = [
    GitSource("https://github.com/NVIDIA/AMGX.git",
              "2b4762f02af2ed136134c7f0570646219753ab3e"),
    DirectorySource("./bundled")
]

script = raw"""
# check if we need to use a more recent glibc
if [[ -f "$prefix/usr/include/sched.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

cd ${WORKSPACE}/srcdir/AMGX*

# Apply all our patches
if [ -d $WORKSPACE/srcdir/patches ]; then
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

install_license LICENSE

mkdir build
cd build
CMAKE_POLICY_DEFAULT_CMP0021=OLD \
CUDA_BIN_PATH=${prefix}/cuda/bin \
CUDA_LIB_PATH=${prefix}/cuda/lib64 \
CUDA_INC_PATH=${prefix}/cuda/include \
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_FIND_ROOT_PATH="${prefix}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=${CXX_STANDARD} \
      -DCUDA_ARCH=${CUDA_ARCHS} \
      -DCUDA_TOOLKIT_ROOT_DIR="${prefix}/cuda" \
      -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
      -Wno-dev \
      ..

make -j${nproc} all
make install

# clean-up
## unneeded static libraries
rm ${libdir}/*.a ${libdir}/sublibs/*.a
"""

augment_platform_block = CUDA.augment

platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11"),
]

# some platforms need a newer glibc, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ["intel", "power"]
end

products = [
    LibraryProduct("libamgxsh", :libamgxsh),
]

versions_to_build = [
    v"11.0",
    v"11.1", # CUSOLVER ABI break
    v"12.0",
]

cuda_archs = Dict(
    v"11.0" => "60;70;80",
    v"11.1" => "60;70;80",
    v"12.0" => "60;70;80",
)

# build AMGX for all supported CUDA toolkits
for cuda_version in versions_to_build, platform in platforms
    augmented_platform = Platform(arch(platform), os(platform);
                                  cuda=CUDA.platform(cuda_version))
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = [
        BuildDependency(PackageSpec(name="CUDA_full_jll",
                                    version=CUDA.full_version(cuda_version))),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]

    if cuda_version >= v"12"
        # CUDA 12 requires glibc 2.17
        # which isn't compatible with current Linux kernel headers,
        # so use the next packaged version
        push!(dependencies, BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.19");
                    platforms=glibc_platforms),)
    end

    if cuda_version >= v"11"
        CXX_STANDARD=14
        preferred_gcc_version = v"5"
    else
        CXX_STANDARD=11
        preferred_gcc_version = v"4"
    end

    preamble = """
    CUDA_ARCHS="$(cuda_archs[cuda_version])"
    CXX_STANDARD=$(CXX_STANDARD)
    """

    build_tarballs(ARGS, name, version, sources, preamble*script, [augmented_platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block,
                   dont_dlopen=true, preferred_gcc_version)
end
