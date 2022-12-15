using BinaryBuilder

include(joinpath(dirname(dirname(@__DIR__)), "platforms", "cuda.jl"))
include(joinpath(dirname(dirname(@__DIR__)), "fancy_toys.jl"))


name = "Extrae"
version = v"4.0.2" # NOTE this is version 4.0.2rc1. its release candidate, but we needed a patch for Binutils 2.39
sources = [
    GitSource("https://github.com/bsc-performance-tools/extrae", "5eb2a8ad56aca035b1e13b021a944143e59e6b4a"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd ${WORKSPACE}/srcdir/extrae

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-autoconf-replace-pointer-size-check-by-AC_CHECK_SIZE.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-autoconf-use-simpler-endianiness-check.patch

if [ $(uname -m) == "aarch64" ]; then
    export ENABLE_ARM64=1
fi

if [ -d "$prefix/cuda" ]; then
    export ENABLE_CUDA=1
fi

autoreconf -fvi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    ${ENABLE_ARM64:+--enable-arm64} \
    --without-dyninst \
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
    # Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]

platforms = expand_cxxstring_abis(platforms)

cuda_version = v"10.2.89"
cuda_platforms = map(platforms) do platform
    Platform(arch(platform), os(platform); libc="glibc", cuda=CUDA.platform(cuda_version))
end

# filter aarch64 + cuda
cuda_platforms = filter(==("x86_64") ∘ arch, platforms)

products = [
    LibraryProduct("libseqtrace", :libseqtrace),
    LibraryProduct("libpttrace", :libpttrace),
    ExecutableProduct("extrae-cmd", :extrae_cmd),
    ExecutableProduct("extrae-header", :extrae_header),
    ExecutableProduct("extrae-loader", :extrae_loader),
]

cuda_product = [
    LibraryProduct("libcudatrace", :libcudatrace),
]

dependencies = [
    Dependency("Binutils_jll"),
    Dependency("LibUnwind_jll"),
    Dependency("PAPI_jll"),
    Dependency("XML2_jll"),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_version), platforms=cuda_platforms),
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll", version=cuda_version), platforms=cuda_platforms),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

for platform in cuda_platforms
    should_build_platform(triplet(platform)) || continue

    build_tarballs(ARGS, name, version, sources, script, [platform], vcat(products, cuda_product), dependencies; julia_compat="1.6", lazy_artifacts=true, CUDA.augment)
end
