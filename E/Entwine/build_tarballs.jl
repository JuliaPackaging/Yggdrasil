# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Entwine"
version = v"2.2.0"

# Collection of sources required to complete build
# Cmake build needs patching
sources = [
    GitSource("https://github.com/connormanning/entwine/",
              "49ad52f985536cb8987d079402377cac50360cf3"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/entwine

if [[ ${target} == *mingw* ]]; then
    
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-replace-msvc-find-shlwapi.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-remove-msvc-warning-options.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-remove-dupenv-branch.patch
fi

if [[ ${target} == *-linux-musl* ]]; then

    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-remove-backtrace-detection.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-hardcode-curl-link.patch

    if [[ ${target} == x86_64-* ]]; then
        # otherwise get "undefined reference to getrandom" error message on x86_64
        rm /usr/lib/libexpat*
    fi
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
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.6")
