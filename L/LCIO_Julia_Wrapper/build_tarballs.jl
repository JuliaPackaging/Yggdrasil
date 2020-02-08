# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO_Julia_Wrapper"
version = v"0.7.0"

# Collection of sources required to build LCIOWrapBuilder
lcio_sources = [
		"https://github.com/jstrube/LCIO_Julia_Wrapper/archive/v$(version).tar.gz" => "1e817bb196f9fdb0fe264c4e5e14744c3df0e9d8ebabae3a0c4be54e31470f74"
]
julia_sources = Dict(
	"x86_64-w64-mingw32" => ["https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-w64-mingw32.tar.gz" => "9c58bc0873e52cf6c41108a7a2b100f68419478f10c6fe635197b1bf47eec64d"], 
	"x86_64-linux-gnu-cxx03" => ["https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz" => "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"],
	"x86_64-linux-gnu-cxx11" => ["https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz" => "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"],
	"x86_64-apple-darwin14-cxx11" => ["https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-apple-darwin14.tar.gz" => "a9537f53306f9cf4f0f376f737c745c16b78e9cf635a0b22fbf0562713454b10"],
	"x86_64-apple-darwin14-cxx03" => ["https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-apple-darwin14.tar.gz" => "a9537f53306f9cf4f0f376f737c745c16b78e9cf635a0b22fbf0562713454b10"]
)

# Bash recipe for building across all platforms
script = raw"""
ln -s ${WORKSPACE}/srcdir/include/ /opt/${target}/${target}/sys-root/usr/local
cd ${WORKSPACE}/srcdir/LCIO_Julia_Wrapper*
mkdir build && cd build
cmake -DJulia_PREFIX=${WORKSPACE}/srcdir -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
VERBOSE=ON cmake --build . --config Release --target install
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
	"libcxxwrap_julia_jll",
	"LCIO_jll"
]
include("../../fancy_toys.jl")

# Use only one build_tarballs call to register. This will accumulate files into `products` and also wrappers into the JLL package.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
register_platform = pop!(platforms)
for p in platforms
	if should_build_platform(triplet(p))
		sources = copy(lcio_sources)
		append!(sources, julia_sources[triplet(p)])
		build_tarballs(non_reg_ARGS, name, version, sources, script, [p], products, dependencies; preferred_gcc_version=v"7")
	end
end
sources = copy(lcio_sources)
append!(sources, julia_sources[triplet(register_platform)])
build_tarballs(ARGS, name, version, sources, script, [register_platform], products, dependencies; preferred_gcc_version=v"7")
