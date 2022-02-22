using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../../fancy_toys.jl")


name = "TorchCUDA"
version = v"1.10.2"

common_sources = [
    GitSource("https://github.com/dhairyagandhi96/Torch.jl.git", "85bd08d39e7fba29ec4a643f60dd006ed8be8ede"),
]

cuda_10_sources = [
    ArchiveSource("https://download.pytorch.org/libtorch/cu102/libtorch-shared-with-deps-1.10.2%2Bcu102.zip", "fa3fad287c677526277f64d12836266527d403f21f41cc2e7fb9d904969d4c4a"; unpack_target = "x86_64-linux-gnu-cxx03"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu102/libtorch-cxx11-abi-shared-with-deps-1.10.2%2Bcu102.zip", "83e43d63d0e7dc9d57ccbdac8a8d7edac6c9e18129bf3043be475486b769a9c2"; unpack_target = "x86_64-linux-gnu-cxx11"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu102/libtorch-win-shared-with-deps-1.10.2%2Bcu102.zip", "0ce2ccd959704cd85c44ad1f3f335c56734c7ff09418bd563e07d5bb7142510c"; unpack_target = "x86_64-w64-mingw32"),
]

cuda_11_sources = [
    ArchiveSource("https://download.pytorch.org/libtorch/cu113/libtorch-shared-with-deps-1.10.2%2Bcu113.zip", "fa3fad287c677526277f64d12836266527d403f21f41cc2e7fb9d904969d4c4a"; unpack_target = "x86_64-linux-gnu-cxx03"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu113/libtorch-cxx11-abi-shared-with-deps-1.10.2%2Bcu113.zip", "83e43d63d0e7dc9d57ccbdac8a8d7edac6c9e18129bf3043be475486b769a9c2"; unpack_target = "x86_64-linux-gnu-cxx11"),
    ArchiveSource("https://download.pytorch.org/libtorch/cu113/libtorch-win-shared-with-deps-1.10.2%2Bcu113.zip", "0ce2ccd959704cd85c44ad1f3f335c56734c7ff09418bd563e07d5bb7142510c"; unpack_target = "x86_64-w64-mingw32"),
]

script = raw"""
mkdir -p $includedir $libdir $prefix/share

cd $WORKSPACE/srcdir

mv cudnn $prefix
if [[ $target == *linux* ]]; then
    cd $bb_full_target
else
    cd $target
fi
mv libtorch/share/* $prefix/share/
mv libtorch/lib/* $libdir
rm -r libtorch/lib
rm -r libtorch/share
mv libtorch/* $prefix
rm -r libtorch

mkdir -p /usr/local/cuda/lib64
cd /usr/local/cuda/lib64
ln -s ${prefix}/cuda/lib64/libcudart.so libcudart.so
ln -s ${prefix}/cuda/lib64/libnvToolsExt.so libnvToolsExt.so

cd $WORKSPACE/srcdir/Torch.jl/build
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$prefix -DTorch_DIR=$prefix/share/cmake/Torch -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda ..
cmake --build .

cp -r $WORKSPACE/srcdir/Torch.jl/build/build/*.${dlext} "${libdir}"
rm -rf $prefix/cuda
install_license ${WORKSPACE}/srcdir/Torch.jl/LICENSE
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms; skip = !Sys.islinux)

products = [
    LibraryProduct("libdoeye_caml", :libdoeye_caml, dont_dlopen = true),
    LibraryProduct("libtorch", :libtorch, dont_dlopen = true),
]

dependencies = [Dependency(PackageSpec(name="CUDA_loader_jll"))]

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5", v"11.6"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    if cuda_version.major == 10
        sources = vcat(common_sources, cuda_10_sources)
    elseif cuda_version.major == 11
        sources = vcat(common_sources, cuda_11_sources)
    end

    for platform in platforms
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true,
                       preferred_gcc_version = v"7.1.0")
    end
end
