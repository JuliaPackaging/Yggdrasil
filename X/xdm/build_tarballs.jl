# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xdm"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xyce/xdm.git", "c87548b0bdd4d696ea103008d452082907951fc3"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xdm
atomic_patch -p1 ../patches/pyinterp.patch
atomic_patch -p1 ../patches/musl.patch
mv $prefix/lib/libboost_python.$dlext /workspace/destdir/lib/libboost_python38.$dlext || true
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBoost_NO_BOOST_CMAKE=ON
make -j$nproc
make install
"""

# No windows python support in Yggdrasil at the moment
platforms = filter(!Sys.iswindows, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("SpiritExprCommon", :SpiritExprCommon, "xdm_bundle"),
    LibraryProduct("XdmRapidXmlReader", :XdmRapidXmlReader, "xdm_bundle"),
    LibraryProduct("SpiritCommon", :SpiritCommon, "xdm_bundle")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boostpython_jll", uuid="398de629-0a17-50a6-9837-8b3a70a53854"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
