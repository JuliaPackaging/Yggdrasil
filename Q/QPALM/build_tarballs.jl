# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QPALM"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kul-optec/QPALM.git","9bd94ef60ca5d82cd8d5f05ac7efd5a449e501c0"),
    GitSource("https://github.com/kul-optec/LADEL.git", "70ad69a621756e72b164dee302a826f9cc111c55"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd QPALM
rmdir LADEL
mv ../LADEL .
cmake -Bbuild-jl -SQPALM \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_INSTALL_PREFIX:PATH=${prefix} \
    -DQPALM_WITH_JULIA:BOOL=On \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=On
cmake --build build-jl -j
cmake --install build-jl --component julia_modules
mv LICENSE LICENSE.QPALM
install_license LICENSE.QPALM
mv LADEL/LICENSE LICENSE.LADEL
install_license LICENSE.LADEL
mv LADEL/thirdparty/SuiteSparse/AMD/Doc/License.txt LICENSE.AMD
install_license LICENSE.AMD
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libqpalm_jll", :libqpalm_jll),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
