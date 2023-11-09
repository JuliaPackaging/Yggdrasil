# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Increment to rebuild without version bump
# Build count: 1
name = "mousetrap"
version = v"0.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Clemapfel/mousetrap.git", "94ce32a135b90952bd2d280d620628767babb6f3"),
    GitSource("https://github.com/Clemapfel/mousetrap_julia_binding.git", "59543cfb885107305438b4fe022d654da65b2e23"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
echo -e "[binaries]\ncmake='/usr/bin/cmake'" >> cmake_toolchain_patch.ini
cd mousetrap
install_license LICENSE
meson setup build --cross-file=$MESON_TARGET_TOOLCHAIN --cross-file=../cmake_toolchain_patch.ini
meson install -C build
cd ../mousetrap_julia_binding
meson setup build --cross-file=$MESON_TARGET_TOOLCHAIN --cross-file=../cmake_toolchain_patch.ini -DJulia_INCLUDE_DIRS=$prefix/include/julia
meson install -C build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[]
include("../../L/libjulia/common.jl")
for version in [v"1.7.0", v"1.8.2", v"1.9.0", v"1.10", v"1.11"]
    for platform in libjulia_platforms(version)
        if nbits(platform) != 32
            push!(platforms, platform)
        end
    end
end
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmousetrap", :mousetrap),
    LibraryProduct("libmousetrap_julia_binding", :mousetrap_julia_binding)
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)
# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GLEW_jll")
    Dependency("GLU_jll"; platforms = x11_platforms)
    Dependency("GTK4_jll")
    Dependency("libadwaita_jll")
    Dependency("OpenGLMathematics_jll")
    Dependency("libcxxwrap_julia_jll")
    BuildDependency("libjulia_jll")
    BuildDependency("Xorg_xorgproto_jll"; platforms = x11_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7", preferred_gcc_version = v"9")

