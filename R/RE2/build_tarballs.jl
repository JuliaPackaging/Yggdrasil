# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "RE2"
tag = "2022-06-01"
version = VersionNumber(replace(tag, "-" => "."))

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/re2/archive/refs/tags/$tag.tar.gz", "f89c61410a072e5cbcf8c27e3a778da7d6fd2f2b5b1445cd4f4508bee946ab0f"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/re2-*

mkdir build_dir && cd build_dir

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DBUILD_SHARED_LIBS=ON)

# Until https://github.com/google/re2/issues/390 is fixed
if [[ ${target} == *mingw* ]]; then
    sed -i 's/cxx_std_11/cxx_std_17/g' ../CMakeLists.txt
fi

cmake .. "${CMAKE_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libre2", :libre2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
#GDAL uses a preferred of 6 so match that
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
