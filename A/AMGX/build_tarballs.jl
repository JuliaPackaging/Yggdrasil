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
git submodule update --init --recursive

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
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
      -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
      -Wno-dev \
      ..

make -j${nproc} install

# clean-up
## unneeded static libraries
rm ${libdir}/*.a ${libdir}/sublibs/*.a
"""

augment_platform_block = CUDA.augment

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# some platforms need a newer glibc, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ["intel", "power"]
end

products = [
    LibraryProduct("libamgxsh", :libamgxsh),
]

# build AMGX for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    dependencies = CUDA.required_dependencies(platform; static_sdk=true)

    cuda_version = VersionNumber(platform["cuda"])
    if cuda_version >= v"12"
        # CUDA 12 requires glibc 2.17
        # which isn't compatible with current Linux kernel headers,
        # so use the next packaged version
        push!(dependencies,
              BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.19");
                              platforms=glibc_platforms),)
    end

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block,
                   dont_dlopen=true, preferred_gcc_version=v"9")
end
