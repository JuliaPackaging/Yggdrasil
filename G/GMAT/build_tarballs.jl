# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GMAT"
version = v"2020.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/gmat/GMAT/GMAT-R2020a/GMAT-src-R2020a.zip", "943f403ac04d958b313b1d99d64fd09e3fa8e4c65363809d5bb88dd8c66e43e4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add --upgrade cmake --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
cd GMAT-R2020a/
cp -r $WORKSPACE/srcdir/patches/cmake .
dos2unix plugins/EstimationPlugin/src/base/measurement/Ionosphere/Ionosphere.hpp
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-Remove-hard-coded-CSPICE-paths.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0002-Remove-MSVC-flags.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0003-Fix-non-portable-cast.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0004-Use-std-chrono-on-all-platforms.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0005-Use-Linux-typedefs-for-cross-compile.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0006-Use-standard-CMake-boost-module.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0007-Remove-explicit-Ws2_32-linking.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0008-Use-standard-install-locations.patch"
mkdir builddir
cd builddir/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
  -DGMAT_INCLUDE_GUI=OFF \
  -DCSPICE_LIB=${libdir}/libcspice.${dlext} -DCSPICE_DIR=${prefix} -DCSPICE_INCLUDE_DIR=${includedir} \
  -DF2C_DIR=${includedir} \
  ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libGmatFunction", :libgmatfunction, "plugins"),
    LibraryProduct("libGmatUtil", :libgmatutil),
    LibraryProduct("libScriptTools", :libgmatscripttools, "plugins"),
    LibraryProduct("libCInterface", :libgmatcinterface),
    LibraryProduct("libGmatBase", :libgmatbase),
    # FIXME: Enable once Python_jll is available for Windows
    # LibraryProduct("libPythonInterface", :libgmatpythoninterface, "plugins"),
    LibraryProduct("libGmatEstimation", :libgmatestimation, "plugins"),
    LibraryProduct("libDataInterface", :libgmatdatainterface, "plugins"),
    LibraryProduct("libYukonOptimizer", :libgmatyukonoptimizer, "plugins"),
    LibraryProduct("libThrustFile", :libgmatthrustfile, "plugins"),
    LibraryProduct("libEphemPropagator", :libgmatephempropagator, "plugins"),
    LibraryProduct("libExtraPropagators", :libgmatextrapropagators, "plugins"),
    LibraryProduct("libNewParameters", :libgmatnewparameters, "plugins"),
    LibraryProduct("libFormation", :libgmatformation, "plugins"),
    LibraryProduct("libPolyhedronGravity", :libgmatpolyhedrongravity, "plugins"),
    LibraryProduct("libStation", :libgmatstation, "plugins"),
    LibraryProduct("libSaveCommand", :libgmatsavecommand, "plugins"),
    LibraryProduct("libEventLocator", :libgmateventlocator, "plugins"),
    LibraryProduct("libProductionPropagators", :libgmatproductionpropagators, "plugins"),
    LibraryProduct("libEKF", :libgmatekf, "plugins"),
    ExecutableProduct("GmatConsole", :gmatconsole)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CSPICE_jll", uuid="07f52509-e9d9-513c-a20d-3b911885bf96"))
    Dependency(PackageSpec(name="Python_jll", uuid="93d3a430-8e7c-50da-8e8d-3dfcfb3baf05"))
    Dependency(PackageSpec(name="Xerces_jll", uuid="637d83c4-b86a-5d90-b82d-5cf0573a8cfc"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
