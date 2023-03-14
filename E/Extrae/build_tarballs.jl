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

# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-autoconf-replace-pointer-size-check-by-AC_CHECK_SIZE.patch
# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-autoconf-use-simpler-endianiness-check.patch
# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0003-autoconf-support-powerpc64le-cross-compilation.patch

if [[ $bb_target = aarch64* ]]; then
    export ENABLE_ARM64=1
fi

if [[ $bb_target = powerpc64le* ]]; then
    export ENABLE_POWERPC64LE=1
fi

if [[ $bb_full_target = *cuda* ]]; then
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
    Platform("x86_64", "Linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]

platforms = expand_cxxstring_abis(platforms)

cuda_versions = [v"10.2.89", v"11.0.3"]
cuda_platforms =
    Iterators.filter(Iterators.product(cuda_versions, platforms)) do (cuda_version, platform)
        if arch(platform) == "powerpc64le" && cuda_version < v"11.0"
            return false
        end

        true
    end |> x -> Iterators.map(x) do (cuda_version, platform)
        Platform(arch(platform), os(platform); cxxstring_abi=cxxstring_abi(platform), libc=libc(platform), cuda=CUDA.platform(cuda_version))
    end |> collect

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
]

cuda_dependencies = [
    BuildDependency("CUDA_full_jll"),
    RuntimeDependency("CUDA_Runtime_jll"),
]

# from 'fancy_toys.jl'
requested_platforms = parse.(Platform, filter(arg -> !occursin(r"^--.*", arg), ARGS))

if iszero(length(requested_platforms)) || (isone(length(requested_platforms)) &&
                                           only(requested_platforms) |> tags |> keys |> (!∋)("cuda"))
    for platform in platforms
        !should_build_platform(platform) && continue

        build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies; julia_compat="1.6")
    end
end

if iszero(length(requested_platforms)) || (isone(length(requested_platforms)) &&
                                           only(requested_platforms) |> tags |> keys |> ∋("cuda"))
    for cuda_platform in cuda_platforms
        !should_build_platform(cuda_platform) && continue

        let dependencies = vcat(dependencies, cuda_dependencies), products = vcat(products, cuda_products)
            build_tarballs(ARGS, name, version, sources, script, [cuda_platform], products, dependencies; julia_compat="1.6", CUDA.augment)
        end
    end
end

