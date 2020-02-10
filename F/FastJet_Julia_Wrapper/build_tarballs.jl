# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FastJet_Julia_Wrapper"
version = v"0.5.0"

# Collection of sources required to build FastJet_Julia_Wrapper
sources = [
   GitSource("https://github.com/jstrube/FastJet_Julia_Wrapper.git", "1ed483a0449a5a7330e0d899492b5c5d2247d47a"; unpack_target="FastJet_Julia_Wrapper"),
   FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-w64-mingw32.tar.gz", "9c58bc0873e52cf6c41108a7a2b100f68419478f10c6fe635197b1bf47eec64d"; unpack_target="x86_64-w64-mingw32"),
   FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz", "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"; unpack_target="x86_64-linux-gnu"), 
   FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-linux-gnu.tar.gz", "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"; unpack_target="x86_64-linux-musl"),
   FileSource("https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-x86_64-apple-darwin14.tar.gz", "a9537f53306f9cf4f0f376f737c745c16b78e9cf635a0b22fbf0562713454b10"; unpack_target="x86_64-apple-darwin14")
]

# Bash recipe for building across all platforms
script = raw"""
ln -s ${WORKSPACE}/srcdir/${target}/include/ /opt/${target}/${target}/sys-root/usr/local
cd ${WORKSPACE}/srcdir/FastJet_Julia_Wrapper/FastJet_Julia_Wrapper*
mkdir build && cd build
cmake -DJulia_PREFIX=${WORKSPACE}/srcdir/${target} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
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
    LibraryProduct("libfastjetwrap", :libfastjetwrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("FastJet_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
