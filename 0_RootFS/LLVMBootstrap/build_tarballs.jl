include("../common.jl")

using BinaryBuilder
Core.eval(BinaryBuilder, :(bootstrap_list = [:rootfs, :platform_support]))

# Collection of sources required to build LLVM
llvm_ver = v"8.0.0"
sources = [
    "http://releases.llvm.org/$(llvm_ver)/llvm-$(llvm_ver).src.tar.xz" =>
    "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c",
    "http://releases.llvm.org/$(llvm_ver)/cfe-$(llvm_ver).src.tar.xz" =>
    "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b",
    "http://releases.llvm.org/$(llvm_ver)/compiler-rt-$(llvm_ver).src.tar.xz" =>
    "b435c7474f459e71b2831f1a4e3f1d21203cb9c0172e94e9d9b69f50354f21b1",
    #"http://releases.llvm.org/$(llvm_ver)/lldb-$(llvm_ver).src.tar.xz" =>
    #"49918b9f09816554a20ac44c5f85a32dc0a7a00759b3259e78064d674eac0373",
    "http://releases.llvm.org/$(llvm_ver)/libcxx-$(llvm_ver).src.tar.xz" =>
    "c2902675e7c84324fb2c1e45489220f250ede016cc3117186785d9dc291f9de2",
    "http://releases.llvm.org/$(llvm_ver)/libcxxabi-$(llvm_ver).src.tar.xz" =>
    "c2d6de9629f7c072ac20ada776374e9e3168142f20a46cdb9d6df973922b07cd",
    "http://releases.llvm.org/$(llvm_ver)/polly-$(llvm_ver).src.tar.xz" =>
    "e3f5a3d6794ef8233af302c45ceb464b74cdc369c1ac735b6b381b21e4d89df4",
    "http://releases.llvm.org/$(llvm_ver)/libunwind-$(llvm_ver).src.tar.xz" =>
    "ff243a669c9cef2e2537e4f697d6fb47764ea91949016f2d643cb5d8286df660",
    "http://releases.llvm.org/$(llvm_ver)/lld-$(llvm_ver).src.tar.xz" =>
    "9caec8ec922e32ffa130f0fb08e4c5a242d7e68ce757631e425e9eba2e1a6e37",
    "./bundled",
]

# Since we kind of do this LLVM setup twice, this is the shared setup start:
script = raw"""
apk add build-base python-dev linux-headers musl-dev

cd $WORKSPACE/srcdir/

# First, move our other projects into llvm/projects
for f in *.src; do
    # Don't symlink llvm itself into llvm/projects...
    if [[ ${f} == llvm-*.src ]]; then
        continue
    fi

    # clang lives in tools/clang and not projects/cfe
    if [[ ${f} == cfe-*.src ]]; then
        mv $(pwd)/${f} $(echo llvm-*.src)/tools/clang
    elif [[ ${f} == polly-*.src ]]; then
        mv $(pwd)/${f} $(echo llvm-*.src)/tools/polly
    elif [[ ${f} == lld-*.src ]]; then
        mv $(pwd)/${f} $(echo llvm-*.src)/tools/lld
    else
        mv $(pwd)/${f} $(echo llvm-*.src)/projects/${f%-*}
    fi
done

# Patch compiler-rt
cd ${WORKSPACE}/srcdir/llvm-*.src/projects/compiler-rt*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/compiler_rt_musl.patch

# Patch libcxx
cd ${WORKSPACE}/srcdir/llvm-*.src/projects/libcxx
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libcxx_musl.patch

# Patch clang
cd ${WORKSPACE}/srcdir/llvm-*.src/tools/clang
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/clang_musl_gcc_detector.patch

# Next, boogie on down to llvm town
cd ${WORKSPACE}/srcdir/llvm-*.src

# This value is really useful later
LLVM_DIR=$(pwd)

# Let's do the actual build within the `build` subdirectory
mkdir build && cd build

CMAKE_FLAGS=()
# We build for all platforms, as we're going to use this to do cross-compilation
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=all)
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST=)

# Turn off docs
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF)

# We want a shared library
CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON -DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
CMAKE_FLAGS+=("-DCMAKE_INSTALL_PREFIX=${prefix}")

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong. We set a bunch of musl-related options here
CMAKE_FLAGS+=("-DLLVM_HOST_TRIPLE=${target}")
CMAKE_FLAGS+=(-DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXX_HAS_GCC_S_LIB=OFF)
CMAKE_FLAGS+=(-DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DCLANG_DEFAULT_RTLIB=compiler-rt)
CMAKE_FLAGS+=(-DLLVM_ENABLE_CXX1Y=ON -DLLVM_ENABLE_PIC=ON)

# Tell compiler-rt to generate builtins for all the supported arches
CMAKE_FLAGS+=(-DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF)

# We don't need libunwind yet
#CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_TOOL_LIBUNWIND_BUILD=OFF"
# Sanitizers don't work on musl yet
#CMAKE_FLAGS="${CMAKE_FLAGS} -DCOMPILER_RT_BUILD_SANITIZERS=OFF"

# Build!
cmake .. ${CMAKE_FLAGS[@]}
cmake -LA || true
make -j${nproc} VERBOSE=1

# Install!
make install -j${nproc} VERBOSE=1

# Lots of tools don't respect `$DSYMUTIL` and so thus do not find 
# our cleverly-named `llvm-dsymutil`.  We create a symlink to help
# Those poor fools along:
#ln -s llvm-dsymutil ${prefix}/bin/dsymutil

# We also need clang++ as well as just plain old clang
#ln -s clang ${prefix}/bin/clang++
"""

# The products that we will ensure are always built
products = [
    # libraries
    LibraryProduct("libLLVM",  :libLLVM)
    LibraryProduct("libLTO",   :libLTO)
    LibraryProduct("libclang", :libclang)
    # tools
    ExecutableProduct("llvm-config", :llvm_config)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_info = build_tarballs(ARGS, "LLVMBootstrap", llvm_ver, sources, script, [host_platform], products, dependencies; skip_audit=true)

# Upload the artifacts
upload_and_insert_shards("JuliaPackaging/Yggdrasil", "LLVMBootstrap", llvm_ver, build_info)
