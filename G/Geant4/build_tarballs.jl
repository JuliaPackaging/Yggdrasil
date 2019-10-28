# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Geant4"
version = v"0.1.0"

# Collection of sources required to build
sources = [
    "https://github.com/Geant4/geant4/archive/v10.5.1.tar.gz" =>
    "443efb0d16e8a5fd195176573d21d2e12415ae7853dd39cc0517171aea243227",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geant4-*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> !isa(p, Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libG4vis_management", :libG4visManagement),
    LibraryProduct("libG4FR", :libG4FR),
    LibraryProduct("libG4event", :libG4Event),
    LibraryProduct("libG4analysis", :libG4Analysis),
    LibraryProduct("libG4digits_hits", :libG4Digits),
    LibraryProduct("libG4run", :libG4Run),
    LibraryProduct("libG4visXXX", :libG4VisXXX),
    LibraryProduct("libG4clhep", :libG4CLHEP),
    LibraryProduct("libG4GMocren", :libG4Mocren),
    LibraryProduct("libG4particles", :libG4Particles),
    LibraryProduct("libG4graphics_reps", :libG4Graphics),
    LibraryProduct("libG4zlib", :libG4Zlib),
    LibraryProduct("libG4geometry", :libG4Geometry),
    LibraryProduct("libG4modeling", :libG4Modeling),
    LibraryProduct("libG4interfaces", :libG4Interfaces),
    LibraryProduct("libG4persistency", :libG4Persistency),
    LibraryProduct("libG4track", :libG4Track),
    LibraryProduct("libG4error_propagation", :libG4ErrorPropagation),
    LibraryProduct("libG4parmodels", :libG4ParModels),
    LibraryProduct("libG4materials", :libG4Material),
    LibraryProduct("libG4physicslists", :libG4PhysicsLists),
    LibraryProduct("libG4VRML", :libG4VRML),
    LibraryProduct("libG4readout", :libG4Readout),
    LibraryProduct("libG4RayTracer", :libG4RayTracer),
    LibraryProduct("libG4visHepRep", :libG4VisHepRep),
    LibraryProduct("libG4Tree", :libG4Tree),
    LibraryProduct("libG4processes", :libG4Processes),
    LibraryProduct("libG4global", :libG4Global),
    LibraryProduct("libG4tracking", :libG4Tracking),
    LibraryProduct("libG4intercoms", :libG4Intercoms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Expat_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
