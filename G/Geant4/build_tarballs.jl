# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Geant4Builder"
version = v"0.1.0"

# Collection of sources required to build Geant4Builder
sources = [
    "https://github.com/Geant4/geant4/archive/v10.5.1.tar.gz" =>
    "443efb0d16e8a5fd195176573d21d2e12415ae7853dd39cc0517171aea243227",

    "https://github.com/libexpat/libexpat/releases/download/R_2_2_8/expat-2.2.8.tar.gz" =>
    "bd507cba42716ca9afe46dd3687fb0d46c09347517beb9770f53a435d2c67ea0",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd expat-2.2.8/
./configure --prefix=$prefix --host=$target
make
make install
cd ../geant4-10.5.1/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libG4vis_management", :libG4visManagement),
    LibraryProduct(prefix, "libexpat", :libexpat),
    LibraryProduct(prefix, "libG4FR", :libG4FR),
    LibraryProduct(prefix, "libG4event", :libG4Event),
    LibraryProduct(prefix, "libG4analysis", :libG4Analysis),
    LibraryProduct(prefix, "libG4digits_hits", :libG4Digits),
    LibraryProduct(prefix, "libG4run", :libG4Run),
    LibraryProduct(prefix, "libG4visXXX", :libG4VisXXX),
    LibraryProduct(prefix, "libG4clhep", :libG4CLHEP),
    LibraryProduct(prefix, "libG4GMocren", :libG4Mocren),
    LibraryProduct(prefix, "libG4particles", :libG4Particles),
    LibraryProduct(prefix, "libG4graphics_reps", :libG4Graphics),
    LibraryProduct(prefix, "libG4zlib", :libG4Zlib),
    LibraryProduct(prefix, "libG4geometry", :libG4Geometry),
    LibraryProduct(prefix, "libG4modeling", :libG4Modeling),
    LibraryProduct(prefix, "libG4interfaces", :libG4Interfaces),
    LibraryProduct(prefix, "libG4persistency", :libG4Persistency),
    LibraryProduct(prefix, "libG4track", :libG4Track),
    LibraryProduct(prefix, "libG4error_propagation", :libG4ErrorPropagation),
    LibraryProduct(prefix, "libG4parmodels", :libG4ParModels),
    LibraryProduct(prefix, "libG4materials", :libG4Material),
    LibraryProduct(prefix, "libG4physicslists", :libG4PhysicsLists),
    LibraryProduct(prefix, "libG4VRML", :libG4VRML),
    LibraryProduct(prefix, "libG4readout", :libG4Readout),
    LibraryProduct(prefix, "libG4RayTracer", :libG4RayTracer),
    LibraryProduct(prefix, "libG4visHepRep", :libG4VisHepRep),
    LibraryProduct(prefix, "libG4Tree", :libG4Tree),
    LibraryProduct(prefix, "libG4processes", :libG4Processes),
    LibraryProduct(prefix, "libG4global", :libG4Global),
    LibraryProduct(prefix, "libG4tracking", :libG4Tracking),
    LibraryProduct(prefix, "libG4intercoms", :libG4Intercoms),
    ExecutableProduct(prefix, "xmlwf", :xmlwf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
