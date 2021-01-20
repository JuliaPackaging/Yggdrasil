using BinaryBuilder, Pkg

name = "AMGX"
version = v"2.1.0"
sources = [
    ArchiveSource("https://github.com/NVIDIA/AMGX/archive/v2.1.0.tar.gz", "6245112b768a1dc3486b2b3c049342e232eb6281a6021fffa8b20c11631f63cc"),
    DirectorySource("./bundled")
]

script = raw"""
# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

# the build system doesn't find libgcc and libstdc++
if [[ "${nbits}" == 32 ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
elif [[ "${target}" != *-apple-* ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

cd ${WORKSPACE}/srcdir/AMGX*
install_license LICENSE
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix-regex-syntax-cmake.patch"

mkdir build
cd build
CMAKE_POLICY_DEFAULT_CMP0021=OLD \
CUDA_BIN_PATH=${prefix}/cuda/bin \
CUDA_LIB_PATH=${prefix}/cuda/lib64 \
CUDA_INC_PATH=${prefix}/cuda/include \
cmake -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_FIND_ROOT_PATH="${prefix}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCUDA_TOOLKIT_ROOT_DIR="${prefix}/cuda" \
      -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64" \
      -Wno-dev \
      ..

make -j${nproc} all
make install

# clean-up
## unneeded static libraries
rm ${libdir}/*.a ${libdir}/sublibs/*.a
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11"),
]

products = [
    LibraryProduct("libamgxsh", :libamgxsh),
]

dependencies = [
    BuildDependency(PackageSpec(name = "CUDA_full_jll", version = "10.0")),
    Dependency(PackageSpec(name = "CUDA_jll", version = "10.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
