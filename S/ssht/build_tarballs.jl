# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ssht"
ssht_version = v"1.5.2"
# We bumped the version because we rebuilt for new architectures
version = v"1.5.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/astro-informatics/ssht.git", "c83fb2a07e1869e875e819523d2e19d91bc8a4bf"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ssht

# Add missing declarations for certain complex long double functions.
# These declarations seem to be missing from our system header files.
# They should be in `<complex.h>` but they aren't.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/complex_long_double.patch

# Build using the regular instructions
mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS_INIT='-fPIC' \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_SYSTEM_LIBRARY_PATH=/opt/${target}/${target}/sys-root/usr/lib64/lp64d \
    -DBUILD_TESTING=OFF \
    ..
cmake --build . --parallel ${nproc}
cmake --install .

# Convert the static into a shared library
whole_archive=$(flagon --whole-archive)
if [ -n "${whole_archive}" ]; then
    whole_archive="-Wl,${whole_archive}"
fi
no_whole_archive=$(flagon --no-whole-archive)
if [ -n "${no_whole_archive}" ]; then
    no_whole_archive="-Wl,${no_whole_archive}"
fi
${CC} -g -fPIC -shared -o ${libdir}/libssht.${dlext} \
    ${whole_archive} ${prefix}/lib/libssht.a ${no_whole_archive} \
    -L${libdir} -lfftw3
rm ${prefix}/lib/libssht.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libssht", :libssht),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll"); compat="3.3.11"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
