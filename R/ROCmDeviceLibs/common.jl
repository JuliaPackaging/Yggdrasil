const NAME = "ROCmDeviceLibs"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "e54681814f72a3657c428f12c9ae0561db7f2972",
    v"4.5.2" => "0f2eb8c16630c1f03a417c7a4248402c356ee510",
    v"5.2.3" => "d999f1780979585119251d4e90c923133a775a8c",
    v"5.4.4" => "4d86a313a33027cff82dc73fe9b8395a7a96eb04",
    v"5.5.1" => "49dd756ee374d648beb3ecd593f419db425ef621",
    v"5.6.1" => "2b9acb09a3808d80c61ab89235a7cf487f52e955")
const ROCM_PLATFORMS = [AnyPlatform()]

const ROCM_PATCHES = Dict(
    v"5.6.1" => raw"""
    atomic_patch -p1 $WORKSPACE/srcdir/patches/irif-no-memory-rw.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/ocml-builtins-rename.patch
    atomic_patch -p1 $WORKSPACE/srcdir/patches/ockl-no-ballot.patch
    """
)

const BUILDSCRIPT = raw"""
# Remove to avoid using incorrect one... :/
rm /opt/bin/x86_64-linux-musl-libgfortran4-cxx11/x86_64-linux-musl-ld.lld
rm /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-ld.lld

CC=${WORKSPACE}/srcdir/rocm-clang \
CXX=${WORKSPACE}/srcdir/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_DIR=${prefix}/llvm/lib/cmake/llvm \
    -DLLD_DIR=${prefix}/llvm/lib/cmake/lld \
    -DClang_DIR=${prefix}/llvm/lib/cmake/clang \
    ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/ROCm-Device-Libs*/LICENSE.TXT
"""

const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
    """ * get(ROCM_PATCHES, version, "") *
    raw"""
    mkdir build && cd build
    """ * BUILDSCRIPT

    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
        DirectorySource("../scripts"),
    ]
    if version in keys(ROCM_PATCHES)
        push!(sources, DirectorySource("./bundled"))
    end
    # Compile devlibs with older LLVM version than what's used in ROCmLLVM
    # for Julia compatibility.
    llvm_version = min(v"5.4.4", version)
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=llvm_version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("Zlib_jll"),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
