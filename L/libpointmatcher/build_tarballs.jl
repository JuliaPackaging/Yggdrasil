# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpointmatcher"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ethz-asl/libpointmatcher.git", "fc7cd5da39b24665d65e6a570124621b4e1d3ef2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpointmatcher/

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/comment-cmake-alias.patch

mkdir build && cd build

# Fix path of libnabo.  TODO: This has to be fixed in libnabo_jll.
sed -i "s?${prefix}/lib?${libdir}?" ${prefix}/share/libnabo/cmake/libnaboConfig.cmake

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DPOINTMATCHER_BUILD_EXAMPLES=OFF \
    -DPOINTMATCHER_BUILD_EVALUATIONS=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DBUILD_SHARED_LIBS=ON

make -j${nproc}
make install

install_license ../debian/copyright

# Delete modified file from libnabo
rm ${prefix}/share/libnabo/cmake/libnaboConfig.cmake
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = expand_cxxstring_abis(supported_platforms())
#only supports 64 bit compilers
filter!(p -> nbits(p) != 32, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libpointmatcher", :libpointmatcher)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    Dependency("boost_jll"; compat="=1.76.0")
    Dependency(PackageSpec(name="libnabo_jll", uuid="569caa04-3db7-54b1-b5fe-10f3ec93054b"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
