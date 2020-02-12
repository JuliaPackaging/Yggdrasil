# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO_Julia_Wrapper"
version = v"0.7.0"

# Collection of sources required to build LCIOWrapBuilder
sources = [
	FileSource("https://github.com/jstrube/LCIO_Julia_Wrapper/archive/v$(version).tar.gz", "1e817bb196f9fdb0fe264c4e5e14744c3df0e9d8ebabae3a0c4be54e31470f74"; unpack_target="LCIO_Julia_Wrapper"),
	FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz", "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"; unpack_target="x86_64-linux-gnu"),
	FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-apple-darwin14.tar.gz", "a9537f53306f9cf4f0f376f737c745c16b78e9cf635a0b22fbf0562713454b10"; unpack_target="x86_64-apple-darwin14"),
]

# Bash recipe for building across all platforms
script = raw"""
ln -s ${WORKSPACE}/srcdir/${target}/include/ /opt/${target}/${target}/sys-root/usr/local
cd ${WORKSPACE}/srcdir/LCIO_Julia_Wrapper/LCIO_Julia_Wrapper-*
mkdir build && cd build
cmake -DJulia_PREFIX=${WORKSPACE}/srcdir/${target} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency("libcxxwrap_julia_jll"),
	Dependency("LCIO_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
