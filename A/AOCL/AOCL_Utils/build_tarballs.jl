# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "AOCL_Utils"
version = v"5.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/amd/aocl-utils.git", "aaa5a385032a05973745cef9e8d7349fb5ba6cda"),
    DirectorySource("../bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# Replace the old CMake with the one from CMake_jll
apk del cmake
cd $WORKSPACE/srcdir/aocl-utils

export CXXFLAGS="-static-libstdc++ -static-libgcc"
export LDFLAGS="-static-libstdc++ -static-libgcc"

if [[ "${target}" == *"musl"* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/au_X86Cpu_linux-musl.patch
fi

cmake -B default -DCMAKE_INSTALL_PREFIX=${prefix} -DAU_BUILD_STATIC_LIBS=OFF
cmake --build default --config release -j${nproc}
cmake --install default --config release

install_license License.txt
"""

# Only Linux and Windows platforms supported by AOCL
platforms = expand_cxxstring_abis(supported_platforms(;
    exclude=p -> !(arch(p) == "x86_64" && (Sys.islinux(p) || Sys.iswindows(p)))))

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll"))
]

products = [
    LibraryProduct("libaoclutils", :aoclutils)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6")
