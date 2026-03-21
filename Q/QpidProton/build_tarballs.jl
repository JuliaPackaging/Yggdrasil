using BinaryBuilder, Pkg

name = "QpidProton"
version = v"0.40.0"  # Use the current stable version of Qpid Proton

# Collection of sources required to complete build
# "https://downloads.apache.org/qpid/proton/0.40.0/qpid-proton-0.40.0.tar.gz"

sources = [
    ArchiveSource(
        "https://downloads.apache.org/qpid/proton/$(version)/qpid-proton-$(version).tar.gz",
        "0acb39e92d947e30175de0969a5b2e479e2983bc3e3d69c835ee5174610e9636"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qpid-proton-*

mkdir build && cd build
cmake -B . \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_PYTHON=OFF \
      -DBUILD_GO=OFF \
      -DBUILD_TESTING=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Skip Windows for now due to build complexities
filter!(p -> !Sys.iswindows(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqpid-proton", :libqpid_proton),
    LibraryProduct("libqpid-proton-core", :libqpid_proton_core),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(name = "OpenSSL_jll", uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.16"
    ),
    Dependency(
        PackageSpec(name = "CyrusSASL_jll", uuid = "6422fedd-75a7-50c2-a7c3-a11dad25a896")
    ),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.10",
    preferred_gcc_version = v"10",
)
