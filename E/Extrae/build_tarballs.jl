using BinaryBuilder
using Base.BinaryPlatforms
using Pkg

include(joinpath(dirname(dirname(@__DIR__)), "fancy_toys.jl"))
include(joinpath(dirname(dirname(@__DIR__)), "platforms", "cuda.jl"))


name = "Extrae"
version = v"4.0.3"
sources = [
    ArchiveSource("https://ftp.tools.bsc.es/extrae/extrae-$version-src.tar.bz2", "b5139a07dbb1f4aa9758c1d62d54e42c01125bcfa9aa0cb9ee4f863afae93db1"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/extrae-*

atomic_patch -p0 ${WORKSPACE}/srcdir/patches/0004-cuda-cupti-undefined-structs-since-v12.patch

if [[ $bb_target = aarch64* ]]; then
    export ENABLE_ARM64=1
fi

if [[ $bb_target = powerpc64le* ]]; then
    export ENABLE_POWERPC64LE=1
fi

if [[ $bb_full_target = *cuda\+[0-9]* ]]; then
    export ENABLE_CUDA=1
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

cuda_versions_to_build = Any[v"11.0", nothing] #= v"12.1", =#

products = [
    LibraryProduct("libseqtrace", :libseqtrace),
    LibraryProduct("libpttrace", :libpttrace),
    ExecutableProduct("extrae-cmd", :extrae_cmd),
    ExecutableProduct("extrae-header", :extrae_header),
    ExecutableProduct("extrae-loader", :extrae_loader),
]

cuda_products = [
    LibraryProduct("libcudatrace", :libcudatrace, dont_dlopen=true),
]

dependencies = BinaryBuilder.AbstractDependency[
    Dependency("Binutils_jll"),
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
