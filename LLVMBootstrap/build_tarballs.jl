include("../common.jl")

using BinaryBuilder
Core.eval(BinaryBuilder, :(bootstrap_mode = true))

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
]

# Since we kind of do this LLVM setup twice, this is the shared setup start:
script = raw"""
apk add build-base python-dev linux-headers

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

# Next, boogie on down to llvm town
cd llvm-*.src

# This value is really useful later
LLVM_DIR=$(pwd)

# Let's do the actual build within the `build` subdirectory
mkdir build && cd build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=""
CMAKE_CXX_FLAGS=""
CMAKE_C_FLAGS=""
CMAKE_FLAGS=""

# We build for all platforms, as we're going to use this to do cross-compilation
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_TARGETS_TO_BUILD:STRING=\"all\""
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_BUILD_TYPE=Release"

# We want a build with no bindings
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_BINDINGS_LIST=\"\" "

# Turn off ZLIB and XML2
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_ENABLE_ZLIB=OFF"
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_ENABLE_LIBXML2=OFF"

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_INCLUDE_DOCS=Off"
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_ENABLE_TERMINFO=Off"
CMAKE_FLAGS="${CMAKE_FLAGS} -DHAVE_HISTEDIT_H=Off"
CMAKE_FLAGS="${CMAKE_FLAGS} -DHAVE_LIBEDIT=Off"

# We want a shared library
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON"
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_LINK_LLVM_DYLIB:BOOL=ON"

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX=${prefix}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_CROSSCOMPILING=True"

# Julia expects the produced LLVM tools to be installed into tools and not bin
# We can't simply move bin to tools since on MingW64 it will also contain the shlib.
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_TOOLS_INSTALL_DIR=${prefix}/tools"

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_HOST_TRIPLE=${target}"

# We don't need libunwind yet
CMAKE_FLAGS="${CMAKE_FLAGS} -DLLVM_TOOL_LIBUNWIND_BUILD=OFF"

# Build!
cmake .. ${CMAKE_FLAGS} -DCMAKE_C_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_C_FLAGS}" -DCMAKE_CXX_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}"
cmake -LA || true
make -j${nproc} VERBOSE=1

# Install!
make install -j${nproc} VERBOSE=1

# move clang products out of $prefix/bin to $prefix/tools
mv ${prefix}/bin/clang* ${prefix}/tools/
mv ${prefix}/bin/scan-* ${prefix}/tools/
mv ${prefix}/bin/c-index* ${prefix}/tools/
mv ${prefix}/bin/git-clang* ${prefix}/tools/
mv ${prefix}/bin/lld* ${prefix}/tools/

# Lots of tools don't respect `$DSYMUTIL` and so thus do not find 
# our cleverly-named `llvm-dsymutil`.  We create a symlink to help
# Those poor fools along:
ln -s llvm-dsymutil ${prefix}/tools/dsymutil

# We also need clang++ as well as just plain old clang
ln -s clang ${prefix}/tools/clang++
"""

# BB is using musl as a platform and we don't want to run glibc binaries on it.
platforms = [BinaryProvider.Linux(:x86_64, :musl)]

# The products that we will ensure are always built
products(prefix) = [
    # libraries
    LibraryProduct(prefix, "libLLVM",  :libLLVM)
    LibraryProduct(prefix, "libLTO",   :libLTO)
    LibraryProduct(prefix, "libclang", :libclang)
    # tools
    ExecutableProduct(joinpath(prefix, "tools", "llvm-config"), :llvm_config)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
name = "LLVM"

build_tarballs(ARGS, name, llvm_ver, sources, script, platforms, products, dependencies; skip_audit=true)
