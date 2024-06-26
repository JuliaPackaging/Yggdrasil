using BinaryBuilder
using BinaryBuilderBase
using Base.BinaryPlatforms
using Pkg

include(joinpath(dirname(dirname(@__DIR__)), "fancy_toys.jl"))
include(joinpath(dirname(dirname(@__DIR__)), "platforms", "cuda.jl"))
include(joinpath(dirname(dirname(@__DIR__)), "platforms", "mpi.jl"))


name = "Extrae"
version = v"4.1.7"
sources = [
    ArchiveSource("https://ftp.tools.bsc.es/extrae/extrae-$version-src.tar.bz2", "0ed87449f74db0abc239ee8c40176e89f9ca6a69738fe751ec0df8fc46da1712"),
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
    export FLAGS_CUDA=--with-cuda=$prefix/cuda
    export CPPFLAGS="-I${prefix}/cuda/include"
fi

if [[ $bb_full_target = *mpi* ]] && [[ $bb_full_target != *mpi\+none* ]]; then
    export FLAGS_MPI="--with-mpi=$prefix --with-mpi-binaries=${bindir} --with-mpi-headers=${includedir} --with-mpi-libs=${libdir}"
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
    ${FLAGS_MPI:---without-mpi} \
    ${FLAGS_CUDA:---without-cuda} \
    --with-binutils=$prefix \
    --with-unwind=$prefix \
    --with-xml=$prefix \
    --with-papi=$prefix

make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)
# (Almost) Same as PAPI
cuda_platforms = CUDA.supported_platforms(; max_version=v"12.2")
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

mpi_platforms, mpi_dependencies = MPI.augment_platforms(platforms)
filter!(platform -> platform["mpi"] != "mpitrampoline", mpi_platforms)

# Concatenate the platforms _after_ the C++ string ABI expansion, otherwise the
# `platform in platforms` test below is meaningless.
all_platforms = [platforms; cuda_platforms; mpi_platforms]

# Only for the non-CUDA platforms, add the cuda=none tag, if necessary.
for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end

    if !haskey(platform, "mpi")
        platform["mpi"] = "none"
    end
end

# Some platforms need glibc 2.19+, because the default one is too old
glibc_platforms = filter(all_platforms) do p
    libc(p) == "glibc" && proc_family(p) in ("intel", "power")
end

products = [
    LibraryProduct("libseqtrace", :libseqtrace, dont_dlopen=true),
    LibraryProduct("libpttrace", :libpttrace, dont_dlopen=true),
    ExecutableProduct("extrae-cmd", :extrae_cmd),
    ExecutableProduct("extrae-header", :extrae_header),
    ExecutableProduct("extrae-loader", :extrae_loader),
    ExecutableProduct("mpi2prv", :mpi2prv)
]

cuda_products = [
    LibraryProduct("libcudatrace", :libcudatrace, dont_dlopen=true),
    # LibraryProduct("libcudampitrace", :libcudampitrace, dont_dlopen=true),
]

mpi_products = [
    LibraryProduct("libmpitrace", :libmpitrace, dont_dlopen=true),
]

dependencies = [
    # `MADV_HUGEPAGE` and `MAP_HUGE_SHIFT` require glibc 2.19, but we only
    # package glibc 2.17 on some architectures.
    BuildDependency(PackageSpec(name="Glibc_jll", version=v"2.19"); platforms=glibc_platforms),
    Dependency("Binutils_jll"; compat="~2.41"),
    Dependency("LibUnwind_jll"),
    Dependency("PAPI_jll"; compat="~7.1"),
    Dependency("XML2_jll"; compat="2.12.0"),
    RuntimeDependency("CUDA_Runtime_jll"; platforms=cuda_platforms),
]

init_block = raw"""
ENV["EXTRAE_SKIP_AUTO_LIBRARY_INITIALIZE"] = "1"
"""

for platform in all_platforms
    should_build_platform(platform) || continue

    _dependencies = [
        dependencies;
        if haskey(platform, "cuda") && platform["cuda"] != "none"
            [BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(VersionNumber(platform["cuda"]))))]
        elseif haskey(platform, "mpi") && platform["mpi"] != "none"
            mpi_dependencies
        else
            []
        end...
    ]

    _products = [
        products;
        if haskey(platform, "cuda") && platform["cuda"] != "none"
            cuda_products
        elseif haskey(platform, "mpi") && platform["mpi"] != "none"
            mpi_products
        else
            []
        end...
    ]

    augment_platform_block = if haskey(platform, "cuda") && platform["cuda"] != "none"
        CUDA.augment
    elseif haskey(platform, "mpi") && platform["mpi"] != "none"
        MPI.augment
    else
        ""
    end

    build_tarballs(ARGS, name, version, sources, script, [platform],
        _products, _dependencies; lazy_artifacts=true,
        julia_compat="1.6", augment_platform_block, init_block,
        preferred_gcc_version=v"5")
end
