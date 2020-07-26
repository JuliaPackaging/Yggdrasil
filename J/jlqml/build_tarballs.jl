# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jlqml"
version = v"0.1.3"

const is_yggdrasil = haskey(ENV, "BUILD_BUILDNUMBER")
git_repo = is_yggdrasil ? "https://github.com/barche/jlqml.git" : joinpath(ENV["HOME"], "src/julia/jlqml/.git")
unpack_target = is_yggdrasil ? "" : "jlqml"

# Collection of sources required to complete build
sources = [
    GitSource(git_repo, "7cfe4025dff8ecdbdffb1178943c53f073e9d212", unpack_target=unpack_target),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/Julia_jll.jl/releases/download/Julia-v1.4.1+1/Julia.v1.4.1.x86_64-linux-gnu-libgfortran4-cxx11.tar.gz", "378b6a23ce4363eeb7afd5bd8092f902caa512f2f987dfc47fc51ae6bdff0e56"; unpack_target="julia-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/Julia_jll.jl/releases/download/Julia-v1.4.1+1/Julia.v1.4.1.x86_64-w64-mingw32-libgfortran4-cxx11.tar.gz", "621029838e895bf5f201d0858fdbd31f1bb7f458aa0bc0646b4b30185a7d8e7c"; unpack_target="julia-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/Julia_jll.jl/releases/download/Julia-v1.4.1+1/Julia.v1.4.1.armv7l-linux-gnueabihf-libgfortran4-cxx11.tar.gz", "0d733c2e0147d6ffb731b638a8b1bd4225069c5735df22bc3a953dffce663d74"; unpack_target="julia-arm-linux-gnueabihf"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/Julia_jll.jl/releases/download/Julia-v1.4.1+1/Julia.v1.4.1.x86_64-apple-darwin14-libgfortran4-cxx11.tar.gz", "f6d94a3184b0241f20f78523de581949afa038f3e320fb9fd20a83019968adca"; unpack_target="julia-x86_64-apple-darwin14"),
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

Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target

mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX -DCMAKE_FIND_ROOT_PATH=$prefix -DJlCxx_DIR=$prefix/lib/cmake/JlCxx -DQt5Core_DIR=$prefix/lib/cmake/Qt5Core -DQt5Quick_DIR=$prefix/lib/cmake/Qt5Quick -DQt5Svg_DIR=$prefix/lib/cmake/Qt5Svg -DQt5Widgets_DIR=$prefix/lib/cmake/Qt5Widgets -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} $macos_extra_flags -DCMAKE_BUILD_TYPE=Release ../jlqml/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/jlqml*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlqml", :libjlqml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("Qt_jll"),
    BuildDependency("Libglvnd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
