# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Minuit2"
version = v"6.18.04"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/root-project/root/archive/v6-18-04.tar.gz", "82421a5f0486a2c66170300285dce49a961e3459cb5290f6fa579ef617dc8b0a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/root-*/math/minuit2
sed -i '/^add_library(Minuit2$/a SHARED' src/CMakeLists.txt
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-DMATHCORE_STANDALONE=1 ..
make -j ${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # We have to manually build the shared library
    mkdir -p "${libdir}"
    cd "${prefix}/lib"
    ar x libMinuit2.dll.a
    cc -shared -o "${libdir}/libMinuit2.dll" *.o
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libMinuit2", :libMinuit2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
