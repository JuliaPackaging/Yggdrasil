# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "TDSControl"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AppeltansPieter/TDSControl.git", "9aa43f98bfcd9a508c7d69945db10164839963cf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license ${WORKSPACE}/srcdir/TDSControl/LICENSE
cmake -S TDSControl -B build -DCMAKE_PREFIX_PATH=${prefix} -DJulia_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DJULIA_BINDINGS=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!((p) -> arch(p) == "x86_64", platforms)
filter!((p) -> os(p) == "linux" || os(p) == "windows", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libtdscontroljl", :libtdscontroljl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70", version=v"3.4.0+0"))
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7", preferred_gcc_version = v"12.1.0")
