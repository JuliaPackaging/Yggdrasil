# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qlever"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ad-freiburg/qlever.git", "1d5503c65c604ce8fb5869da7f4f249a28be9dba"),
    GitSource("https://github.com/joka921/stxxl.git", "b9e44f0ecba7d7111fbb33f3330c3e53f2b75236"),
    ArchiveSource("https://github.com/google/googletest/archive/refs/tags/release-1.11.0.tar.gz",
                  "b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5"),
    # GitSource("https://github.com/google/re2.git", "0dade9ff39bb6276f18dd6d4bc12d3c20479ee24"),
    GitSource("https://github.com/abseil/abseil-cpp.git", "215105818dfde3174fe799600bb0f3cae233d0bf"),
    GitSource("https://github.com/antlr/antlr4.git", "e4c1a74c66bd5290364ea2b36c97cd724b247357")
]


# Bash recipe for building across all platforms
script = raw"""

mv $WORKSPACE/srcdir/googletest-release-1.11.0/googletest $WORKSPACE/srcdir/qlever/third_party/googletest

rm -r $WORKSPACE/srcdir/qlever/third_party/antlr4
mv $WORKSPACE/srcdir/antlr4 $WORKSPACE/srcdir/qlever/third_party/

rm -r $WORKSPACE/srcdir/qlever/third_party/stxxl
mv $WORKSPACE/srcdir/stxxl $WORKSPACE/srcdir/qlever/third_party/

rm -r $WORKSPACE/srcdir/qlever/third_party/abseil-cpp
mv $WORKSPACE/srcdir/abseil-cpp $WORKSPACE/srcdir/qlever/third_party/

cd $WORKSPACE/srcdir/qlever/

export GOOGLETEST_VERSION=1.11.0
export ABSL_PROPAGATE_CXX_STD=ON

cmake -DCMAKE_BUILD_TYPE=Release -DLOGLEVEL=DEBUG -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DUSE_PARALLEL=true -DABSL_PROPAGATE_CXX_STD=ON -GNinja . && ninja
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700"))
    Dependency(PackageSpec(name="Git_jll", uuid="f8c6e375-362e-5223-8a59-34ff63f689eb"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"))
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
