# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Minuit2"
version = v"6.34.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://root.cern/download/root_v6.34.02.source.tar.gz", "166bec562e420e177aaf3133fa3fb09f82ecddabe8a2e1906345bad442513f94")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/root-*/math/minuit2

sed -i '/^add_library(Minuit2$/a SHARED' src/CMakeLists.txt
sed -i '/^add_library(Minuit2Math$/a SHARED' src/math/CMakeLists.txt
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -Dminuit2_standalone=ON ..
make -j ${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # We have to manually build the shared library
    mkdir -p "${libdir}"
    cd "${prefix}/lib"
    ar x libMinuit2.dll.a
    cc -shared -o "${libdir}/libMinuit2.dll" *.o
    rm *.o
    ar x libMinuit2Math.dll.a
    cc -shared -o "${libdir}/libMinuit2Math.dll" *.o
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter(p -> libc(p) != "musl" && 
                        os(p) != "freebsd" && 
                        arch(p) != "armv6l" && 
                        arch(p) != "i686", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libMinuit2", :libMinuit2)
    LibraryProduct("libMinuit2Math", :libMinuit2Math)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
