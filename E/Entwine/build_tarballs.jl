# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Entwine"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/connormanning/entwine/archive/refs/tags/$version.tar.gz", "c12989e417182aa43a574d58eac284d4ea422abd5ac041504f55f635905e9b32"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/entwine-*

#this is needed for v2.1.0, but has been fixed on master, so can probably get rid of next version release
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/add-pdal-lasheader.patch

if [[ ${target} == *mingw* ]]; then
    #this is needed for v2.1.0, but has been fixed on master, so can probably get rid of next version release
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-lowercase-shlwapi.patch

    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-remove-msvc-shlwapi-lib-search.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-remove-msvc-warning-options.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-shwlapi-hardcode.patch
fi

if [[ ${target} == x86_64-linux-musl* ]]; then
    # otherwise get "undefined reference to getrandom" error message
    rm /usr/lib/libexpat*
    
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-remove-backtrace-detection.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-hardcode-curl-link.patch
fi

mkdir build
cd build

cmake .. -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_LIBRARY_PATH:FILEPATH="${libdir}" \
    -DCMAKE_INCLUDE_PATH:FILEPATH="${includedir}" \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_TESTS=OFF

ninja -j${nproc}
ninja install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libentwine", :libentwine),
    ExecutableProduct("entwine", :entwine)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PDAL_jll", uuid="a8197b14-d70b-5660-b10f-8b1ebb62825c"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.6")
