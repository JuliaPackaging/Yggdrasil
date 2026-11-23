using BinaryBuilder
using BinaryBuilderBase
using Base.BinaryPlatforms
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))


name = "Extrae"
version = v"4.2.0"
ygg_version = v"4.2.1"  # the CUDA_Runtime_jll, MPI and julia compat bounds changed
sources = [
    ArchiveSource("https://ftp.tools.bsc.es/extrae/extrae-$version-src.tar.bz2", "7b83a1ed008440bbc1bda88297d2d0e9256780db1cf8401b3c12718451f8919a"),
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
    export FLAGS_CUDA="--with-cuda=$prefix/cuda --with-cupti=$prefix/cuda"
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
cuda_platforms = CUDA.supported_platforms(; max_version=v"12.3.999")
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

# Extrae doesn't support the standard MPI ABI yet: its configure only looks for the
# implementations' own library names (not libmpi_abi), and its Fortran wrappers take
# `MPI_Message` to be an integer, which the standard ABI makes a pointer. Re-enable
# `mpiabi` once upstream handles both.
excluded_mpi_abis = ("mpitrampoline", "mpiabi")

mpi_platforms, mpi_dependencies = MPI.augment_platforms(platforms)
filter!(platform -> platform["mpi"] ∉ excluded_mpi_abis, mpi_platforms)

cudampi_platforms, cudampi_dependencies = MPI.augment_platforms(cuda_platforms)
filter!(platform -> platform["mpi"] ∉ excluded_mpi_abis, cudampi_platforms)

# Concatenate the platforms _after_ the C++ string ABI expansion, otherwise the
# `platform in platforms` test below is meaningless.
all_platforms = [platforms; cuda_platforms; mpi_platforms; cudampi_platforms]

for platform in all_platforms
    # Only for the non-CUDA platforms, add the cuda=none tag, if necessary.
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end

    # Only for the non-MPI platforms, add the mpi=none tag, if necessary.
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
    LibraryProduct("libptcudatrace", :libptcudatrace, dont_dlopen=true),
]

mpi_products = [
    ExecutableProduct("mpimpi2prv", :mpimpi2prv),
    LibraryProduct("libmpitrace", :libmpitrace, dont_dlopen=true),
    LibraryProduct("libptmpitrace", :libptmpitrace, dont_dlopen=true),
]

cudampi_products = [
    LibraryProduct("libcudampitrace", :libcudampitrace, dont_dlopen=true),
    LibraryProduct("libptcudampitrace", :libptcudampitrace, dont_dlopen=true),
]

dependencies = [
    # `MADV_HUGEPAGE` and `MAP_HUGE_SHIFT` require glibc 2.19, but we only
    # package glibc 2.17 on some architectures. The linker can't read the
    # compressed debug sections of Glibc_jll 2.19.1.
    BuildDependency(PackageSpec(name="Glibc_jll", version="2.19.0"); platforms=glibc_platforms),
    Dependency("Binutils_jll"; compat="~2.41"),
    Dependency("LibUnwind_jll"),
    # PAPI_jll 7.1.1 falls back to its CPU build where it has no matching CUDA build.
    Dependency("PAPI_jll"; compat="~7.1.1"),
    # XML2 breaks its ABI in minor releases:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # MPICH_jll 5 requires Hwloc_jll 2.12.2+, which requires XML2_jll 2.13.6+.
    Dependency("XML2_jll"; compat="~2.13.6"),
    CUDA.required_dependencies(all_platforms)...,
]

augment_platform_block = CUDA.augment_with(MPI.augment, "augment_mpi!")

init_block = raw"""
ENV["EXTRAE_SKIP_AUTO_LIBRARY_INITIALIZE"] = "1"
"""

for platform in all_platforms
    should_build_platform(platform) || continue

    _dependencies = copy(dependencies)
    if platform["cuda"] != "none" && platform["mpi"] != "none"
        append!(_dependencies, cudampi_dependencies)
    elseif platform["mpi"] != "none"
        append!(_dependencies, mpi_dependencies)
    end

    _products = copy(products)
    if platform["cuda"] != "none"
        append!(_products, cuda_products)
    end
    if platform["mpi"] != "none"
        append!(_products, mpi_products)
    end
    if platform["cuda"] != "none" && platform["mpi"] != "none"
        append!(_products, cudampi_products)
    end

    # CUDA_Runtime_jll requires Julia 1.10. MPICH_jll 5 only has libgfortran5 builds,
    # which the build environment provides from GCC 8.
    build_tarballs(ARGS, name, ygg_version, sources, script, [platform],
        _products, _dependencies; lazy_artifacts=true,
        julia_compat="1.10", augment_platform_block, init_block,
        preferred_gcc_version=v"8")
end
