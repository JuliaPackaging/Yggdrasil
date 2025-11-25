# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pugixml"
version_string = "1.15"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://github.com/zeux/pugixml/releases/download/v$(version_string)/pugixml-$(version_string).tar.gz",
                  "655ade57fa703fb421c2eb9a0113b5064bddb145d415dd1f88c79353d90d511a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pugixml*
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libpugixml", :libpugixml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
