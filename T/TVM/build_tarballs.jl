# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TVM"
version = v"0.6.1"

sources = [
    GitSource("https://github.com/dmlc/tvm.git", "f552d4df8c356f5bb6b7fbef9b9cdac65d674d54"),
    GitSource("https://github.com/dmlc/dlpack.git", "0acb731e0e43d15deee27b66f10e4c5b4e667913"),
    GitSource("https://github.com/dmlc/dmlc-core.git", "808f485387f9a03f78fa9f1159f387d0d91b7a28"),
    GitSource("https://github.com/agauniyal/rang.git", "cabe04d6d6b05356fa8f9741704924788f0dd762"),
]

# Bash recipe for building across all platforms
script = raw"""
# Start by moving things into the proper places
for submodule in dlpack dmlc-core rang; do
    rm -rf "${WORKSPACE}/srcdir/tvm/3rdparty/${submodule}"
    mv "${WORKSPACE}/srcdir/${submodule}" "${WORKSPACE}/srcdir/tvm/3rdparty/${submodule}"
done

# Next, enter TVM and start building it
cd $WORKSPACE/srcdir/tvm

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${prefix}" \
         -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
         -DUSE_LLVM=ON
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),

    # Fails with can't find `execinfo.h`
    #Linux(:x86_64; libc=:musl),
    MacOS(:x86_64),

    # dll import woes
    #Windows(:x86_64),
]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libtvm", :libtvm),
    LibraryProduct("libtvm_topi", :libtvm_topi),
    LibraryProduct("libtvm_runtime", :libtvm_runtime),
    LibraryProduct("libnnvm_compiler", :libnnvm_compiler),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="LLVM_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

