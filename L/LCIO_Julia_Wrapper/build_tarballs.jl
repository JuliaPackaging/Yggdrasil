# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIOWrapBuilder"
version = v"0.7"

# Collection of sources required to build LCIOWrapBuilder
sources = [
    Dict("https://github.com/jstrube/LCIOWrapBuilder/archive/$(version).tar.gz" => "")
]

# Bash recipe for building across all platforms
script = raw"""
	wget https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-${target}.tar.gz
	tar xzf julia-1.3.0-${target}.tar.gz
	export PATH=$(pwd)/juliabin/bin:${PATH}
	ln -s ${WORKSPACE}/srcdir/juliabin/include/ /opt/${target}/${target}/sys-root/usr/local
	cd ${WORKSPACE}/srcdir
	mkdir build && cd build
	cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
	#cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.toolchain -DCMAKE_FIND_ROOT_PATH=${prefix} -DJulia_PREFIX=${prefix} ..
	VERBOSE=ON cmake --build . --config Release --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	"libcxxwrap_julia_jll",
	"LCIO_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")

