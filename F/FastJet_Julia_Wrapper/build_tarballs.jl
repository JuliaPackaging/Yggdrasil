# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FastJetWrapBuilder"
version_number = get(ENV, "TRAVIS_TAG", "")
if version_number == ""
    version_number = "v0.99"
end
version = VersionNumber(version_number)

# Collection of sources required to build Fjwbuilder
sources = [
	   "FastJet_Julia_Wrapper"
]

# Bash recipe for building across all platforms
script = raw"""
wget https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-${target}.tar.gz
mkdir julia
cd julia
tar xf ../julia-1.0.0-${target}.tar.gz
export PATH=$(pwd)/bin:${PATH}
ln -s ${WORKSPACE}/srcdir/julia/include/ /opt/${target}/${target}/sys-root/usr/local
cd ${WORKSPACE}/srcdir
mkdir build && cd build
export JlCxx_DIR=${prefix}
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
VERBOSE=ON cmake --build . --config Release --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    MacOS(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfastjetwrap", :libfastjetwrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	"libcxxwrap_julia_jll",
	"Fastjet_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
