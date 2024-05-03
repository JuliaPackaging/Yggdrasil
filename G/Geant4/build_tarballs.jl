# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Geant4"
version = v"11.2.1"

# Collection of sources required to build
sources = [
    ArchiveSource("https://gitlab.cern.ch/geant4/geant4/-/archive/v$(version)/geant4-v$(version).tar.gz",
                  "76c9093b01128ee2b45a6f4020a1bcb64d2a8141386dea4674b5ae28bcd23293"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geant4-*/

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/windows.patch
fi

mkdir build && cd build
FLAGS=()
if [[ "${target}" != *-w64-* && "${target}" != *-apple-* ]]; then
    FLAGS=(-DGEANT4_USE_OPENGL_X11=ON)
fi
if [[ "${target}" == *-w64-* ]]; then
    FLAGS+=(-DGEANT4_BUILD_MULTITHREADED=OFF)
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DGEANT4_INSTALL_DATA=ON \
      -DGEANT4_USE_GDML=ON \
      -DGEANT4_BUILD_TLS_MODEL=global-dynamic \
      "${FLAGS[@]}" \
    ..
make -j${nproc}
make install

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter(p -> libc(p) != "musl" && os(p) != "freebsd" && arch(p) != "armv6l" && arch(p) != "i686", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libG4vis_management", :libG4visManagement),
    LibraryProduct("libG4FR", :libG4FR),
    LibraryProduct("libG4event", :libG4Event),
    LibraryProduct("libG4analysis", :libG4Analysis),
    LibraryProduct("libG4digits_hits", :libG4Digits),
    LibraryProduct("libG4run", :libG4Run),
    LibraryProduct("libG4clhep", :libG4CLHEP),
    LibraryProduct("libG4GMocren", :libG4Mocren),
    LibraryProduct("libG4particles", :libG4Particles),
    LibraryProduct("libG4graphics_reps", :libG4Graphics),
    LibraryProduct("libG4zlib", :libG4Zlib),
    LibraryProduct("libG4geometry", :libG4Geometry),
    LibraryProduct("libG4modeling", :libG4Modeling),
    LibraryProduct("libG4interfaces", :libG4Interfaces),
    LibraryProduct("libG4mctruth", :libG4MCTruth),
    LibraryProduct("libG4geomtext", :libG4GeomText),
    LibraryProduct("libG4gdml", :libG4GDML),
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
    LibraryProduct("libG4ptl", :libG4Ptl),
    LibraryProduct("libG4ToolsSG", :libG4ToolsSG),
    FileProduct("share/Geant4/data", :data_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="2.4.8"),
    Dependency("Xorg_libXmu_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Xerces_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
