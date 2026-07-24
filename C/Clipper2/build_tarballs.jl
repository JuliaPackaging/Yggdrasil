# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clipper2"
version = v"2.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AngusJohnson/Clipper2.git", "21ebba05db8894f0c7217ad35ea518080f324946"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd Clipper2/CPP/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCLIPPER2_TESTS=OFF \
    -DCLIPPER2_EXAMPLES=OFF \
    -DCLIPPER2_UTILS=OFF \
    ..
make -j${nproc}
make install

# Build the C wrapper (a flat C ABI over the C++ API, for FFI consumers such as
# Julia's ccall — mirrors C/Clipper's bundled cwrapper). One library, compiled
# -DUSINGZ and linked against libClipper2Z: Point64 then carries a third int64;
# the narrow {x,y} entry points construct it with z=0, and the *_z entry points
# expose it. The -fvisibility flags keep the wrapper's exports to the
# functions marked DLL_PUBLIC (no Clipper2/STL template instantiations);
# -L${prefix}/lib covers Windows, where ${libdir} is the DLL directory but
# the import library lands in ${prefix}/lib.
cd ${WORKSPACE}/srcdir
install -Dvm 644 cwrapper/cclipper2.h "${includedir}/cclipper2.h"
${CXX} -std=c++17 -O2 -fPIC -shared -DUSINGZ \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -I${includedir} \
    -o "${libdir}/libcclipper2.${dlext}" \
    cwrapper/cclipper2.cpp \
    -L${libdir} -L${prefix}/lib -lClipper2Z

# BSL-1.0 covers both Clipper2 and the bundled wrapper.
install_license Clipper2/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libClipper2", :libClipper2),
    LibraryProduct("libClipper2Z", :libClipper2Z),
    LibraryProduct("libcclipper2", :libcclipper2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 10 is the newest compiler compatible with the declared julia_compat:
# Julia 1.6 ships libstdc++ from GCC 10, so GCC 11+ output (GLIBCXX_3.4.29)
# would not load there. Clipper2 itself only needs C++17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10")
