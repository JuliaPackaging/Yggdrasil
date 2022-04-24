# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

julia_versions = [v"1.6.3", v"1.7.0", v"1.8.0", v"1.9.0"]

name = "jlqml"
version = v"0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/barche/jlqml.git", "4d21e2fcf0bcae29c45e76c8ac9d1d45893a77e6"),
]

# Bash recipe for building across all platforms
script = raw"""
if test -f "$prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake"; then
    sed -i 's/_qt5gui_find_extra_libs.*AGL.framework.*//' $prefix/lib/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake
fi

# Override compiler ID to silence the horrible "No features found" cmake error
if [[ $target == *"apple-darwin"* ]]; then
  macos_extra_flags="-DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
fi

mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    -DQt5Core_DIR=$prefix/lib/cmake/Qt5Core \
    -DQt5Quick_DIR=$prefix/lib/cmake/Qt5Quick \
    -DQt5Svg_DIR=$prefix/lib/cmake/Qt5Svg \
    -DQt5Widgets_DIR=$prefix/lib/cmake/Qt5Widgets \
    $macos_extra_flags \
    ../jlqml/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/jlqml*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> libc(p) != "musl", platforms) # Qt_jll is currently not available for muslc
# Qt5Declarative_jll is not available for these architectures:
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlqml", :libjlqml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("Qt5Declarative_jll"),
    Dependency("Qt5Svg_jll"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"9",
    julia_compat = "1.6")
