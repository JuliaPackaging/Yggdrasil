# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ClassicFlang"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flang-compiler/flang.git", "a459f3ca34b244c6c1e59d6495e8ec90952c2448"),
    GitSource("https://github.com/flang-compiler/classic-flang-llvm-project.git", "528906c87cd4cae63a52c3170365cb382daf94cb"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Begin (LLVM + flang driver) build
mkdir llvm-build
cd llvm-build/

## Apply LLVM patches
atomic_patch -p1 -d ../classic-flang-llvm-project ../patches/0010-add-musl-triples.patch

## Configure & Build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_CLASSIC_FLANG=ON -DLLVM_ENABLE_PROJECTS="clang;openmp" ../classic-flang-llvm-project/llvm/
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
cat /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-clang | sed 's/clang/flang/g' > /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-flang
chmod +x /opt/bin/x86_64-linux-musl-cxx11/x86_64-linux-musl-flang
ln -s ${WORKSPACE}/destdir/bin/flang /opt/x86_64-linux-musl/bin/flang

## Configure & Build
export PATH=${WORKSPACE}/srcdir/flang-build/bin:$PATH
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_Fortran_COMPILER_ARG1="--sysroot=/opt/x86_64-linux-musl/x86_64-linux-musl/sys-root" -DCMAKE_Fortran_COMPILER=x86_64-linux-musl-flang -DCMAKE_Fortran_COMPILER_ID=Flang -DCMAKE_BUILD_TYPE=Release -DWITH_WERROR=OFF ../flang
make -j$(nproc)
make install
install_license ../flang/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "musl"),
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("flang", :flang),
    ExecutableProduct("flang1", :flang1),
    ExecutableProduct("flang2", :flang2)
    # TODO: Runtime libraries?
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"10", lock_microarchitecture=false)
