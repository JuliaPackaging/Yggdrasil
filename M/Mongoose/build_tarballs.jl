# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mongoose"
version = v"7.18.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cesanta/mongoose.git", "ccfe7e0724dd9bd4a6c447c84552e0ca47767ce8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cat > CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.10)
project(mongoose C)

add_library(mongoose SHARED mongoose/mongoose.c)
install(TARGETS mongoose
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin)

install(FILES mongoose/LICENSE DESTINATION share/licenses/Mongoose)
EOF

cmake -B build  \
    -DCMAKE_INSTALL_PREFIX=${prefix}  \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}  \
    -DCMAKE_BUILD_TYPE=Release  \
    -S .
cmake --build build --parallel ${nproc}
cmake --install build
install_license mongoose/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmongoose", :libmongoose)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
