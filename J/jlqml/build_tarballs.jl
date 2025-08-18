# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)
uuid = Base.UUID("458c3c95-2e84-50aa-8efc-19380b2a3a95")
delete!(Pkg.Types.get_last_stdlibs(v"1.13.0"), uuid)

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "jlqml"
version = v"0.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaGraphics/jlqml.git", "6bb3af77a99b9c82704ce6a59d32db1414cb4ecb"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
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
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12 \
    ../jlqml/

if [[ $target == *"apple-darwin"* ]]; then
  sed -i "s/gnu++20/gnu++17/" CMakeFiles/jlqml.dir/flags.make
  apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
  ln -s /workspace/destdir $apple_sdk_root/usr/local
  sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
  sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
fi

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/jlqml*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
filter!(x -> x >= v"1.10.0",  julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# Qt6Declarative_jll is not available for these architectures:
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlqml", :libjlqml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="0.14.4"),
    Dependency("Qt6Declarative_jll"; compat="~6.8.2"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Svg_jll"; compat="~6.8.2"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10",
    julia_compat = "1.6")
