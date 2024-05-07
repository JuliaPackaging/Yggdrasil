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

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]

# some platforms need glibc 2.19+, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ("intel", "power")
end

cuda_versions_to_build = Any[v"11.4", v"12", nothing]

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

dependencies = BinaryBuilder.AbstractDependency[
    # `MADV_HUGEPAGE` and `MAP_HUGE_SHIFT` require glibc 2.19, but we only
    # package glibc 2.17.
    BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.19");
                    platforms=glibc_platforms),
    Dependency("Binutils_jll"; compat="~2.39"),
    Dependency("LibUnwind_jll"),
    Dependency("PAPI_jll"),
    Dependency("XML2_jll"),
    RuntimeDependency("CUDA_Runtime_jll"),
]

for cuda_version in cuda_versions_to_build, platform in platforms
    # powerpc64le not supported until CUDA 11.0
    if arch(platform) == "powerpc64le" && !isnothing(cuda_version) && cuda_version <= v"11.0"
        continue
    end

    # TODO PAPI_jll 7.0.0+2 does not support CUDA on aarch64 (only x86_64, powerpc64le with glibc)
    if arch(platform) == "aarch64" && !isnothing(cuda_version)
        continue
    end

    platform_tags = [Symbol(k) => v for (k, v) in tags(platform) if k ∉ ("arch", "os")]
    augmented_platform = Platform(arch(platform), os(platform);
        platform_tags...,
        cuda=isnothing(cuda_version) ? "none" : CUDA.platform(cuda_version)
    )
    should_build_platform(triplet(augmented_platform)) || continue

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))))
    end

    build_tarballs(ARGS, name, version, sources, script, [augmented_platform], products, dependencies; julia_compat="1.6", CUDA.augment)
end
