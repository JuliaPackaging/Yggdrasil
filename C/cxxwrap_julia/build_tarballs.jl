# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcxxwrap_julia"
version = v"0.6.5"

# Collection of sources required to complete build
sources = [
    "https://github.com/JuliaInterop/libcxxwrap-julia.git" =>
    "133a1370045b5786e7f176840c4c47be178377e9",
]

# Bash recipe for building across all platforms
script = raw"""
wget https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/julia-1.0.0-${target}.tar.gz
mkdir julia
cd julia
tar xf ../julia-1.0.0-${target}.tar.gz
Julia_PREFIX=$PWD
cd ..
mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../libcxxwrap-julia/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/libcxxwrap-julia*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Windows(:x86_64),
    Windows(:i686),
    MacOS(:x86_64),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcxxwrap_julia", :libcxxwrap_julia),
    LibraryProduct("libcxxwrap_julia_stl", :libcxxwrap_julia_stl)
]
for basename in ["jlcxx_containers", "except", "extended", "functions", "hello", "basic_types", "inheritance", "parametric", "pointer_modification", "types"]
  fullname = "lib"*basename
  push!(products, LibraryProduct(fullname, Symbol(fullname)))
end

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
