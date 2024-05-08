using BinaryBuilder
using BinaryBuilderBase
using Base.BinaryPlatforms
using Pkg

include(joinpath(dirname(dirname(@__DIR__)), "fancy_toys.jl"))
include(joinpath(dirname(dirname(@__DIR__)), "platforms", "cuda.jl"))


name = "Extrae"
version = v"4.1.2"
sources = [
    ArchiveSource("https://ftp.tools.bsc.es/extrae/extrae-$version-src.tar.bz2", "adbc1d3aefde7649262426d471237dc96f070b93be850a6f15280ed86fd0b952"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/extrae-*

# check if we need to use a more recent glibc
if [[ -f "${prefix}/usr/include/bits/mman-linux.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(dirname $(realpath "${prefix}/usr/include/bits/mman-linux.h")))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

# Work around https://github.com/bsc-performance-tools/extrae/issues/103
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-Add-missing-XML2_CFLAGS.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-Add-missing-lxml2.patch

if [[ $bb_target = aarch64* ]]; then
    export ENABLE_ARM64=1
fi

if [[ $bb_target = powerpc64le* ]]; then
    export ENABLE_POWERPC64LE=1
fi

if [[ $bb_full_target = *cuda\+[0-9]* ]]; then
    export ENABLE_CUDA=1
    export CPPFLAGS="-I${prefix}/cuda/include"
fi

autoreconf -fvi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    ${ENABLE_ARM64:+--enable-arm64} \
    ${ENABLE_POWERPC64LE:+--enable-powerpc64le} \
    --without-dyninst \
    --disable-openmp \
    --disable-nanos \
    --disable-smpss \
    --without-mpi \
    ${ENABLE_CUDA:+--with-cuda=$prefix/cuda} \
    --with-binutils=$prefix \
    --with-unwind=$prefix \
    --with-xml-prefix=$prefix \
    --with-papi=$prefix

make -j${nproc}
make install
"""

non_cuda_platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]
non_cuda_platforms = expand_cxxstring_abis(non_cuda_platforms)
# (Almost) Same as PAPI
cuda_platforms = CUDA.supported_platforms(; max_version=v"12.2")
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

# Concatenate the platforms _after_ the C++ string ABI expansion, otherwise the
# `platform in non_cuda_platforms` test below is meaningless.
all_platforms = [non_cuda_platforms; cuda_platforms]

# Some platforms need glibc 2.19+, because the default one is too old
glibc_platforms = filter(all_platforms) do p
    libc(p) == "glibc" && proc_family(p) in ("intel", "power")
end

products = [
    LibraryProduct("libseqtrace", :libseqtrace),
    LibraryProduct("libpttrace", :libpttrace),
    ExecutableProduct("extrae-cmd", :extrae_cmd),
    ExecutableProduct("extrae-header", :extrae_header),
    ExecutableProduct("extrae-loader", :extrae_loader),
    ExecutableProduct("mpi2prv", :mpi2prv)
]

cuda_products = [
    LibraryProduct("libcudatrace", :libcudatrace, dont_dlopen=true),
]

dependencies = [
    # `MADV_HUGEPAGE` and `MAP_HUGE_SHIFT` require glibc 2.19, but we only
    # package glibc 2.17 on some architectures.
    BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.19");
                    platforms=glibc_platforms),
    Dependency("Binutils_jll"; compat="~2.41"),
    Dependency("LibUnwind_jll"),
    Dependency("PAPI_jll"; compat="~7.1"),
    Dependency("XML2_jll"; compat="2.12.0"),
    RuntimeDependency("CUDA_Runtime_jll"),
]

for platform in all_platforms
    # Only for the non-CUDA platforms, add the cuda=none tag, if necessary.
    if platform in non_cuda_platforms && CUDA.is_supported(platform)
        platform["cuda"] = "none"
    end

    should_build_platform(triplet(platform)) || continue

    _dependencies = if !haskey(platform, "cuda") || platform["cuda"] == "none"
        dependencies
    else
        [
            dependencies;
            BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(VersionNumber(platform["cuda"]))))
        ]
    end

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, _dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block=CUDA.augment,
                   preferred_gcc_version=v"5")
end
