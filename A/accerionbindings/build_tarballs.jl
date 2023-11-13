using BinaryBuilder
using Pkg

sources = [        
    DirectorySource("accerionbindings"),
    GitSource("https://gitlab.com/accerion/accerionsensorapi.git", "04eebcb78cbe9cadfccdc8b2ee30d770d9c01320")
]

# Bash recipe for building across all platforms
script = raw"""
cd accerionsensorapi
git submodule update --init --recursive

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE ..
make -j$(nproc) 
make install

cd $WORKSPACE/srcdir
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DJulia_PREFIX=${prefix} ..
cmake --build . --config Release --target install
"""

julia_version = v"1.5.4"
version_number = v"5.4.2"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
	Platform("x86_64", "linux"; libc=:glibc, cxxstring_abi=:cxx11),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaccerionbindings", :libaccerionbindings),
]

# Dependencies that must be installed before this package can be built
dependencies = [
		BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
		Dependency(PackageSpec(name="libcxxwrap_julia_jll"); compat="0.7.1")
]

build_tarballs(ARGS, "accerionbindings", version_number, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
