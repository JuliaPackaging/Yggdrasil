using BinaryBuilder

name = "NNPACK"
version = v"2018.06.22"

# Collection of sources required to build Ogg
sources = [
    "https://github.com/Maratyszcza/NNPACK.git" =>
    "c039579abe21f5756e0f0e45e8e767adccc11852",

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

# On ARM/AArch64, use `clang` instead of `gcc`.
TOOLCHAIN="/opt/${target}/${target}.toolchain"
if [[ "${target}" == arm-* ]] || [[ "${target}" == aarch64-* ]]; then
    TOOLCHAIN="/opt/${target}/${target}_clang.toolchain"
fi

# NNPACK wants "armv7l", not just "arm", so GIVE IT WHAT IT WANTS
# Disabled for now because it thinks we don't have NEON
#if [[ "${target}" == arm-* ]]; then
#    sed -i.bak -e "s/set(CMAKE_SYSTEM_PROCESSOR arm)/set(CMAKE_SYSTEM_PROCESSOR armv7l)/g" "${TOOLCHAIN}"
#fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN}" \
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
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DNNPACK_LIBRARY_TYPE="shared" \
    "${EXTRA_FLAGS[@]}" \
    ..
make -j${nproc} VERBOSE=1
make install
"""

# Build only Linux and MacOS
platforms = filter(p -> (p isa Linux || p isa MacOS), supported_platforms())

# Build only for AArch64, x86_64 and i686 (armv7l disabled for now until NEON support is figured out)
platforms = filter(p -> arch(p) in (:aarch64, :x86_64, :i686), platforms)

# AArch64 musl seems to have problems linking against libgcc_s, admit defeat for now
platforms = filter(p -> !(arch(p) == :aarch64 && libc(p) == :musl), platforms)

# The products that we will ensure are always built
products = prefix -> Product[
    LibraryProduct(prefix, "libnnpack", :libnnpack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
