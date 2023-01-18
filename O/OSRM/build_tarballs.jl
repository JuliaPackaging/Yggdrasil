# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OSRM"
version = v"5.28.0" # UNTAGGED / ASK FOR TAG

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git", "d9df33dd0a492c50632deddd0ddfdfbf3cb5bbd7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/osrm-backend

# Patch boost/phoenix.hpp header path
atomic_patch -p1 ../patches/boost_deprecated_header.patch

mkdir build && cd build
cmake .. \
    -DBZIP2_INCLUDE_DIR=${includedir} \
    -DBZIP2_LIBRARIES=${libdir}/libbz2.${dlext} \
    -DLUA_INCLUDE_DIR=${includedir} \
    -DLUA_LIBRARIES=${libdir}/liblua.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -Wno-dev
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libosrm", :libosrm)
    ExecutableProduct("osrm-routed", :osrm_routed)
    
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
    Dependency(PackageSpec(name="Lua_jll", uuid="a4086b1d-a96a-5d6b-8e4f-2030e6f25ba6"))
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e"))
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
