using BinaryBuilder

name = "NNPACK"
version = v"2018.06.22"

# Collection of sources required to build Ogg
sources = [
    "https://github.com/Maratyszcza/NNPACK.git" =>
    "af40ea7d12702f8ae55aeb13701c09cad09334c3",

    # Buckets of deps
    "https://github.com/Maratyszcza/cpuinfo.git" =>
    "4e8f04355892c5deb64a51731a6afdb544a4294d",
    "https://github.com/Maratyszcza/FP16.git" =>
    "4b37bd31c9cc1380ef9f205f7dd031efe0e847ab",
    "https://github.com/Maratyszcza/FXdiv.git" =>
    "811b482bcd9e8d98ad80c6c78d5302bb830184b0",
    "https://pypi.python.org/packages/e8/59/8c2e293c9c8d60f206fd5d0f6c8236a2e0a97832379ac319077441552c6a/opcodes-0.3.13.tar.gz" =>
    "1859c23143fe20daa4110be87a947cbf3eefa048da71dde642290213f251590c",
    "https://github.com/Maratyszcza/psimd.git" =>
    "3d8bfe7318423462a6d9e0c6537e75efd4822c49",
    "https://github.com/Maratyszcza/PeachPy.git" =>
    "01d15157a973a4ae16b8046313ddab371ea582db",
    "https://pypi.python.org/packages/16/d8/bc6316cf98419719bd59c91742194c111b6f2e85abac88e496adefaf7afe/six-1.11.0.tar.gz" =>
    "70e8a77beed4562e7f14fe23a786b54f6296e34344c23bc42f07b15018ff98e9",
    "https://github.com/Maratyszcza/pthreadpool.git" =>
    "3fb19c58b46f3cbc78a27c7b207a6eb7946633c0",

    "https://github.com/google/googletest/archive/release-1.8.0.tar.gz" =>
    "58a6f4277ca2bc8565222b3bbd58a177609e9c488e8a72649359ba51450db7d8",
]

# Bash recipe for building across all platforms
script = raw"""
# Prepare peachpy
cd ${WORKSPACE}/srcdir/PeachPy
python3 setup.py develop

mkdir ${WORKSPACE}/srcdir/NNPACK/build
cd ${WORKSPACE}/srcdir/NNPACK/build

# If we're on Linux, we need to add in `-lrt` as a library to link against
EXTRA_FLAGS=()
if [[ "${target}" == *-linux-* ]]; then
    EXTRA_FLAGS+=("-DCMAKE_CXX_STANDARD_LIBRARIES=-lrt")
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.toolchain \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DPYTHON_LIBRARY=/usr/lib/libpython3.so \
    -DPYTHON_SIX_SOURCE_DIR=$(echo ${WORKSPACE}/srcdir/six*/) \
    -DPYTHON_OPCODES_SOURCE_DIR=$(echo ${WORKSPACE}/srcdir/opcodes*/) \
    -DPYTHON_PEACHPY_SOURCE_DIR=${WORKSPACE}/srcdir/PeachPy \
    -DCPUINFO_SOURCE_DIR=${WORKSPACE}/srcdir/cpuinfo \
    -DFP16_SOURCE_DIR=${WORKSPACE}/srcdir/FP16 \
    -DFXDIV_SOURCE_DIR=${WORKSPACE}/srcdir/FXdiv \
    -DPSIMD_SOURCE_DIR=${WORKSPACE}/srcdir/psimd \
    -DPTHREADPOOL_SOURCE_DIR=${WORKSPACE}/srcdir/pthreadpool \
    -DGOOGLETEST_SOURCE_DIR=$(echo ${WORKSPACE}/srcdir/googletest*/) \
    "${EXTRA_FLAGS[@]}" \
    ..
make -j${nproc} VERBOSE=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc),
    Linux(:i686, :glibc),
    #Linux(:armv7l, :glibc),
    Linux(:aarch64, :glibc),
    # OSX is broken for the time being.  :(
    #MacOS(:x86_64),
    
    # Looks like NNPACK doesn't support windows.  :(
    #Windows(:x86_64),
    #Windows(:i686),
]

# The products that we will ensure are always built
products = prefix -> Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
