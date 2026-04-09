# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "jlqml"
version = v"0.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaGraphics/jlqml.git", "ddde17dd8925089dba8254a48681600ebde4ea7e"),
]

# Bash recipe for building across all platforms
script = raw"""
# Need newer cmake from JLL
apk del cmake

mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ../jlqml/

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/jlqml*/LICENSE.md
"""

sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms) # No OpenGL on aarch64 freeBSD
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
filter!(p -> arch(p) != "riscv64", platforms) # No OpenGL on riscv64
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlqml", :libjlqml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="0.14.9"),
    Dependency("Qt6Declarative_jll"; compat="~6.10.2"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Svg_jll"; compat="~6.10.2"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("libjulia_jll"),
    HostBuildDependency("CMake_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10",
    julia_compat = "1.6")
