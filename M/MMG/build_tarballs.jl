# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MMG"
version = v"5.8.0"

# Collection of sources required to build MMG
sources = [
    GitSource("https://github.com/MmgTools/mmg", "4d8232c8aebfed877935d75d4d4a67e850962422"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mmg

# MMG builds a small helper program, `genheader`, and runs it at build time to
# generate the Fortran headers.  That does not work when cross-compiling, so
# build it for the host first and put it on the PATH: when cross-compiling,
# CMake does not substitute the `genheader` target name in the custom command
# with the (unrunnable) target executable, and falls back to searching PATH.
cmake -B build-host \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SCOTCH=OFF \
    -DUSE_ELAS=OFF \
    -DUSE_VTK=OFF
cmake --build build-host --parallel ${nproc} --target genheader
install -Dvm 755 build-host/bin/genheader "${host_bindir}/genheader"
rm -rf build-host

if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/MMG.mingw.patch"
fi

# `FindSCOTCH.cmake` wants to run a test program to determine `sizeof(SCOTCH_Num)`,
# which is impossible when cross-compiling.  SCOTCH_jll is built with 32-bit
# integers, so pre-seed the result of the `check_c_source_runs` call.
# Old glibc hides the `PRId32` & co. macros from C++ unless `__STDC_FORMAT_MACROS`
# is defined.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DUSE_SCOTCH=ON \
    -DSCOTCH_DIR=${prefix} \
    -DSCOTCH_Num_4_EXITCODE=0 \
    -DSCOTCH_Num_4_EXITCODE__TRYRUN_OUTPUT="" \
    -DUSE_ELAS=ON \
    -DUSE_VTK=OFF \
    -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmmg", :libmmg),
    LibraryProduct("libmmg2d", :libmmg2d),
    LibraryProduct("libmmg3d", :libmmg3d),
    LibraryProduct("libmmgs", :libmmgs),
    ExecutableProduct("mmg2d_O3", :mmg2d_O3),
    ExecutableProduct("mmg3d_O3", :mmg3d_O3),
    ExecutableProduct("mmgs_O3", :mmgs_O3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LinearElasticity_jll"),
    # Keep the SCOTCH compat in sync with MUMPS_jll, so that both can be
    # installed together: https://github.com/JuliaPackaging/Yggdrasil/issues/14340
    Dependency("SCOTCH_jll"; compat="~7.0.7")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
