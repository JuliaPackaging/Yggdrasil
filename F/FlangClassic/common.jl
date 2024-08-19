# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flang-compiler/flang.git", "a459f3ca34b244c6c1e59d6495e8ec90952c2448"),
    GitSource("https://github.com/flang-compiler/classic-flang-llvm-project.git", "528906c87cd4cae63a52c3170365cb382daf94cb"),
    DirectorySource(joinpath(@__DIR__, "bundled"))
]

# Bash recipe for building across all platforms
function flang_script(build_compiler)
script = build_compiler ? "export build_compiler=1\n" : "export build_compiler=0\n"
script *= raw"""
cd $WORKSPACE/srcdir

# Clear clang leftovers
rm /workspace/x86_64-linux-musl-cxx11/destdir/lib/libclang* || true

# Begin (LLVM + flang driver) build
mkdir llvm-build
cd llvm-build/

## Apply LLVM patches
atomic_patch -p1 -d ../classic-flang-llvm-project ../patches/0010-add-musl-triples.patch
atomic_patch -p1 -d ../classic-flang-llvm-project ../patches/nosincos.patch

## Configure & Build
if [[ ${build_compiler} == 1 ]]; then
    export LLVM_TARGET="-DLLVM_ENABLE_CLASSIC_FLANG=ON -DLLVM_ENABLE_PROJECTS=clang;openmp ../classic-flang-llvm-project/llvm/"
else
    export LLVM_TARGET="-DOPENMP_ENABLE_LIBOMPTARGET=OFF ../classic-flang-llvm-project/openmp"
fi
cmake -GNinja -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ${LLVM_TARGET}
ninja
ninja install
install_license ../classic-flang-llvm-project/llvm/LICENSE.TXT
cd ..

# Begin pgmath build
mkdir pgmath-build
cd pgmath-build
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../flang/runtime/libpgmath/
ninja
ninja install
cd ..

# Begin Flang (Compiler/Runtime) build
mkdir flang-build
cd flang-build

## Apply flang patches
atomic_patch -p1 -d ../flang ../patches/musl-patches.patch
atomic_patch -p1 -d ../flang ../patches/no-fastmath.patch
atomic_patch -p1 -d ../flang ../patches/flang2-install-dir.patch

## Create Compiler wrapper for flang
if [[ ${build_compiler} == 1 ]]; then
    # For the just-built compiler
    cat /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang | sed 's/clang/flang/g' > /opt/bin/${bb_full_target}/${target}-flang
    chmod +x /opt/bin/${bb_full_target}/${target}-flang
    ln -s ${WORKSPACE}/destdir/bin/flang /opt/x86_64-linux-musl/bin/flang
else
    # For the host compiler
    cat /opt/bin/${bb_full_target}/${target}-clang | sed 's/clang/flang/g' > /opt/bin/${bb_full_target}/${target}-flang
    chmod +x /opt/bin/${bb_full_target}/${target}-flang
    ln -s ${WORKSPACE}/x86_64-linux-musl-cxx11/destdir/bin/flang /opt/x86_64-linux-musl/bin/flang

    # Disable building flang1/flang2
    atomic_patch -p1 -d ../flang ../patches/flang-no-tools.patch
fi
export FC=${target}-flang

## Configure & Build
export PATH=${WORKSPACE}/srcdir/flang-build/bin:$PATH
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_Fortran_COMPILER=${FC} -DCMAKE_Fortran_COMPILER_ID=Flang -DCMAKE_BUILD_TYPE=Release -DWITH_WERROR=OFF ../flang

if [[ ${build_compiler} == 1 ]]; then
    make -j$(nproc)
    make install
else
    make -j$(nproc) -C runtime/
    make -j$(nproc) -C runtime/ install
fi

# We already installed the license as `LICENSE.TXT` above.
# Do not install another license as `LICENSE.txt`.
# These file names would conflict on case-insensitive file systems,
# and the generated package is then unusable there.
"""
end

# Dependencies that must be installed before this package can be built
dependencies = Any[
    Dependency("Zlib_jll")
]
