# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenColorIO"
version = v"2.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/OpenColorIO", "592a122b37467c3376f2387fbbdbe7b571fad39f"),
]


# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OpenColorIO*
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DOCIO_BUILD_GPU_TESTS=OFF \
    -DOCIO_BUILD_PYTHON=OFF \
    -DOCIO_BUILD_TESTS=OFF \
    -DOCIO_USE_HEADLESS=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ocioarchive"     , :ocioarchive     ),
    ExecutableProduct("ociobakelut"     , :ociobakelut     ),
    ExecutableProduct("ociocheck"       , :ociocheck       ),
    ExecutableProduct("ociochecklut"    , :ociochecklut    ),
    ExecutableProduct("ociocpuinfo"     , :ociocpuinfo     ),
    ExecutableProduct("ociomakeclf"     , :ociomakeclf     ),
    ExecutableProduct("ocioperf"        , :ocioperf        ),
    ExecutableProduct("ociomergeconfigs", :ociomergeconfigs),
    ExecutableProduct("ociowrite"       , :ociowrite       ),
    ExecutableProduct("ociolutimage"    , :ociolutimage    ),
    ExecutableProduct("ocioconvert"     , :ocioconvert     ),
    LibraryProduct("libOpenColorIO", :libOpenColorIO),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # minizip-ng
    Dependency("Expat_jll"; compat="2.7.3"),
    Dependency("Imath_jll"; compat="3.2.2"),
    Dependency("OpenEXR_jll"; compat="3.4.4"),
    Dependency("Zlib_jll"),
    Dependency("yaml_cpp_jll"; compat="0.8.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
