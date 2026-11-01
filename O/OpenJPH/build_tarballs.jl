using BinaryBuilder

name = "OpenJPH"
version = v"0.32.0"

sources = [
    GitSource("https://github.com/aous72/OpenJPH", "23c422895ce6c3a156935222e4715ee0b7be952c"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenJPH

# We are building with old kernel headers that do not define `HWCAP_SVE2`
atomic_patch -p1 $WORKSPACE/srcdir/patches/sve2.patch
# We are building with an old glibc that does not define `AT_HWCAP2`
atomic_patch -p1 $WORKSPACE/srcdir/patches/hwcap2.patch

cmake_options=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
)

cmake -Bcmake_build -GNinja "${cmake_options[@]}"
cmake --build cmake_build --parallel ${nproc}
cmake --install cmake_build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libopenjph", :libopenjph),
    ExecutableProduct("ojph_compress", :ojph_compress),
    ExecutableProduct("ojph_expand", :ojph_expand),
]

dependencies = [
    Dependency("Libtiff_jll"; compat="4.7.3"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"12")
