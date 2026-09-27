# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pugixml"
version_string = "1.16"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://github.com/zeux/pugixml/releases/download/v$(version_string)/pugixml-$(version_string).tar.gz",
                  "4cee1ca4aad395170f4c7a07824f3bdd41f28316c6e1e1090a1425b278ec0b4b"),
    # XmlStructPugixmlShim: a small extern "C" shim over pugixml's C++ DOM, ccalled by the
    # Julia package XmlStructPugixml.jl (Tom-Lemmens/XmlStructTools.jl). Bundled into this
    # JLL (source vendored under bundled/xmlstructpugixmlshim) rather than shipped as its own
    # package so the shim always builds against the exact pugixml it was verified against, and
    # so this PR only touches one Yggdrasil recipe.
    DirectorySource("./bundled"),
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

cd $WORKSPACE/srcdir/xmlstructpugixmlshim
mkdir -vp "${libdir}"
${CXX} -O2 -std=c++14 -fPIC -shared \
    -I"${includedir}" \
    -o "${libdir}/libxmlstructpugixmlshim.${dlext}" \
    shim.cpp \
    -L"${libdir}" -lpugixml
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libpugixml", :libpugixml),
    LibraryProduct("libxmlstructpugixmlshim", :libxmlstructpugixmlshim),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
