using BinaryBuilder, Pkg

name = "DatabentoJl"
version = v"0.1.0"

# Sources
sources = [
    # 1. Your Package Source (Public GitHub)
    GitSource("https://github.com/harris-azmon/databento-julia.git", "5274c23a3ec711639d2d77e2c2736b0070ea77e2"),

    # 2. Databento C++ Library (v0.30.0)
    GitSource("https://github.com/databento/databento-cpp.git", "49baedc33bd00b24d7503822c0c2ce6274477c18"),

    # 3. License File (copied from source)
    FileSource("https://raw.githubusercontent.com/harris-azmon/databento-julia/5274c23a3ec711639d2d77e2c2736b0070ea77e2/LICENSE", "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4")
]

# Bash recipe for building
script = raw"""
# Move to the C++ wrapper directory
cd $WORKSPACE/srcdir/databento-julia/deps

rm -rf build
mkdir build && cd build

# We use FETCHCONTENT_SOURCE_DIR_DATABENTO to tell CMake to use the
# checked-out databento-cpp from 'sources' instead of downloading it.
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
      -DJulia_INCLUDE_DIRS=${prefix}/include/julia \
      -DJulia_LIBRARY=${prefix}/lib/libjulia.so \
      -DFETCHCONTENT_SOURCE_DIR_DATABENTO=${WORKSPACE}/srcdir/databento-cpp \
      ..

make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/LICENSE
"""

# Platforms we are targeting (Expanding ABIs for C++ compatibility)
platforms = [
    Platform("x86_64", "linux"; libc="glibc")
]
platforms = expand_cxxstring_abis(platforms)

# Products
products = [
    LibraryProduct("libdatabento_jl", :libdatabento_jl; dont_dlopen=true)
]

# Dependencies
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll"), compat="0.13.4"),
    Dependency(PackageSpec(name="OpenSSL_jll")),
    Dependency(PackageSpec(name="Zstd_jll")),
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.7"))
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7", preferred_gcc_version=v"9")
