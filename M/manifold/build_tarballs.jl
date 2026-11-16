# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "manifold"
version = v"3.5.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/elalish/manifold.git", "32271a1a999ce721ffaf5ab10e9746ceeb696547"),
    # The Clipper2 commit that manifold v3.5.5 pins in cmake/manifoldDeps.cmake. Clipper2_jll
    # 2.0.1 is 12 commits older and is built with CLIPPER2_HI_PRECISION, which manifold's own
    # build does not set, so the pinned commit is built here and linked statically, which is
    # what manifold's CMake does whenever no system Clipper2 is found.
    GitSource("https://github.com/AngusJohnson/Clipper2.git", "46f639177fe418f9689e8ddb74f08a870c71f5b4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/manifold

# MANIFOLD_PAR=OFF: upstream checks its cross-architecture determinism with
# threading off. The C bindings (libmanifoldc) need MANIFOLD_CROSS_SECTION.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMANIFOLD_PAR=OFF \
    -DMANIFOLD_CROSS_SECTION=ON \
    -DMANIFOLD_CBIND=ON \
    -DMANIFOLD_TEST=OFF \
    -DMANIFOLD_PYBIND=OFF \
    -DMANIFOLD_USE_BUILTIN_CLIPPER2=ON \
    -DFETCHCONTENT_SOURCE_DIR_CLIPPER2=$WORKSPACE/srcdir/Clipper2 \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON
cmake --build build --parallel ${nproc}
cmake --install build

# Two source directories defeat the automatic license install, and both files
# are called LICENSE.
install_license LICENSE
cp $WORKSPACE/srcdir/Clipper2/LICENSE $WORKSPACE/srcdir/LICENSE.Clipper2
install_license $WORKSPACE/srcdir/LICENSE.Clipper2
"""

# src/impl.cpp calls std::optional::value(), which needs macOS 10.13 on x86_64.
sources, script = require_macos_sdk("10.13", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = filter(platforms) do p
    !Sys.isfreebsd(p) && libc(p) != "musl"
end
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmanifoldc", :libmanifoldc),
]

# Dependencies that must be installed before this package can be built.
# GLM left manifold in 3.0 and Clipper2 is built above, so there are none.
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 11 is the oldest compiler upstream's CI builds with (ubuntu-22.04).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
