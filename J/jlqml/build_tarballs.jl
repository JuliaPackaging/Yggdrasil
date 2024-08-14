# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "jlqml"
version = v"0.6.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaGraphics/jlqml.git", "4cf890e6a556f546082e442a8f21178b195f39d6"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11 \
    ../jlqml/

if [[ $target == *"apple-darwin"* ]]; then
  sed -i "s/gnu++20/gnu++17/" CMakeFiles/jlqml.dir/flags.make
fi

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/jlqml*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# Qt6Declarative_jll is not available for these architectures:
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlqml", :libjlqml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="0.13.2"),
    Dependency("Qt6Declarative_jll"; compat="~6.7.1"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Svg_jll"; compat="~6.7.1"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10",
    julia_compat = "1.6")
