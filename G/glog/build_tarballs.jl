using BinaryBuilder

name = "glog"
version = v"0.6.0"

sources = [
    GitSource("https://github.com/google/glog.git",
              "b33e3bad4c46c8a6345525fd822af355e5ef9446")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glog
# Fix a typo in glog v0.6.0 release that has been removed on master
sed -i 's/Windows.h/windows.h/' src/glog/logging.h.in
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
# No products: Eigen is a pure header library
products = Product[
    LibraryProduct("libglog", :libglog),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("gflags_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
