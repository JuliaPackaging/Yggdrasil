# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

julia_versions = [v"1.6.3", v"1.7.0", v"1.8.0", v"1.9.0"]

name = "ViZDoom"
version = v"1.1.13"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mwydmuch/ViZDoom/archive/refs/tags/$version.tar.gz", "e379a242ada7e1028b7a635da672b0936d99da3702781b76a4400b83602d78c4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ViZDoom-*
mv ../CMakeLists.txt ../ViZDoomJuliaModule.cpp src/lib_julia/
mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CROSSCOMPILING=FALSE \
    -DJulia_PREFIX=${prefix} \
    -DBUILD_JULIA=ON \
    ..
cmake --build . --parallel ${nproc}
cp bin/libvizdoomjl.so bin/vizdoom bin/vizdoom.pk3 ../src/freedoom2.wad ${libdir}
mv ../scenarios $prefix/
install_license $WORKSPACE/srcdir/ViZDoom-*/README.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = [Platform("x86_64", "linux")] #vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# Qt6Declarative_jll is not available for these architectures:
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libvizdoomjl", :libvizdoom),
    FileProduct("scenarios", :scenarios)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll", compat = "^1.76"),
    Dependency("SDL2_jll"),
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"9",
    julia_compat = "1.6")
