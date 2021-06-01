# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GRAMPC"
version = v"2.2"

# The only Julia function used in this library is jl_error, so a version restriction is
# only needed because we need to have one to figure out the allowed platforms to build on.
# In reality, this library should work with other versions without the need to recompile it.
julia_version = v"1.6.0"


# Collection of sources required to complete build
sources = [
    GitSource( "https://github.com/JuDO-dev/grampc_julia_wrapper.git", "93f13feb53f4d27d92fcb29be61d34de0ade8cdf" )
]


# Bash recipe for building across all platforms
script = raw"""
    cd $WORKSPACE/srcdir/grampc_julia_wrapper

    mkdir -p build
    cd build

    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
          -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
          -DCMAKE_C_FLAGS="-I${prefix}/include" \
          -DCMAKE_BUILD_TYPE=Release \
          ../

    make -j${nproc}
    make install

    # Copy the library's license file
    install_license $WORKSPACE/srcdir/grampc_julia_wrapper/src_GRAMPC/LICENSE.txt 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Since we require the Julia library for linking, we can only build on the
# platforms it exists on.
include( "../../L/libjulia/common.jl" )
platforms = libjulia_platforms( julia_version )


# The products that we will ensure are always built
products = [
    LibraryProduct("libgrampc_julia", :libgrampc_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency( PackageSpec( name="libjulia_jll", version=julia_version ) ),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
