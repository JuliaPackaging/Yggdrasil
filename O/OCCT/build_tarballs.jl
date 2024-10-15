# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OCCT"
version = v"7.7.2"

# Collection of sources required to build Open CASCADE Technology (OCCT)
sources = [
    GitSource("https://github.com/Open-Cascade-SAS/OCCT.git",
              "cec1ecd0c9f3b3d2572c47035d11949e8dfa85e2"), # V7_7_2 @ Aug 11, 2023
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OCCT
if [[ ${target} == *musl* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/OSD_MemInfo.cxx.patch"
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/OSD_signal.cxx.patch"
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_StackTrace.cxx.patch"
elif [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/CMakeLists.txt.patch"
elif [[ ${target} == *freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_CString.cxx.patch"
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_StackTrace.cxx.patch"
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/STEPConstruct_AP203Context.cxx.patch"
fi
mkdir build
cd build
cmake -Wno-dev .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_LIBRARY_TYPE=Shared \
    -DBUILD_MODULE_Draw=0 \
    -DBUILD_MODULE_Visualization=0 \
    -DBUILD_MODULE_ApplicationFramework=0
make -j${nproc}
make install
install_license ../LICENSE_LGPL_21.txt ../OCCT_LGPL_EXCEPTION.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(p -> arch(p) != "armv6l", supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libTKBO", :libTKBO),
    LibraryProduct("libTKBRep", :libTKBRep),
    LibraryProduct("libTKBin", :libTKBin),
    LibraryProduct("libTKBinL", :libTKBinL),
    LibraryProduct("libTKBinXCAF", :libTKBinXCAF),
    LibraryProduct("libTKBool", :libTKBool),
    LibraryProduct("libTKCAF", :libTKCAF),
    LibraryProduct("libTKCDF", :libTKCDF),
    LibraryProduct("libTKFeat", :libTKFeat),
    LibraryProduct("libTKFillet", :libTKFillet),
    LibraryProduct("libTKG2d", :libTKG2d),
    LibraryProduct("libTKG3d", :libTKG3d),
    LibraryProduct("libTKGeomAlgo", :libTKGeomAlgo),
    LibraryProduct("libTKGeomBase", :libTKGeomBase),
    LibraryProduct("libTKHLR", :libTKHLR),
    LibraryProduct("libTKIGES", :libTKIGES),
    LibraryProduct("libTKLCAF", :libTKLCAF),
    LibraryProduct("libTKMath", :libTKMath),
    LibraryProduct("libTKMesh", :libTKMesh),
    LibraryProduct("libTKOffset", :libTKOffset),
    LibraryProduct("libTKPrim", :libTKPrim),
    LibraryProduct("libTKRWMesh", :libTKRWMesh),
    LibraryProduct("libTKSTEP", :libTKSTEP),
    LibraryProduct("libTKSTEP209", :libTKSTEP209),
    LibraryProduct("libTKSTEPAttr", :libTKSTEPAttr),
    LibraryProduct("libTKSTEPBase", :libTKSTEPBase),
    LibraryProduct("libTKSTL", :libTKSTL),
    LibraryProduct("libTKService", :libTKService),
    LibraryProduct("libTKShHealing", :libTKShHealing),
    LibraryProduct("libTKTopAlgo", :libTKTopAlgo),
    LibraryProduct("libTKV3d", :libTKV3d),
    LibraryProduct("libTKVCAF", :libTKVCAF),
    LibraryProduct("libTKVRML", :libTKVRML),
    LibraryProduct("libTKXCAF", :libTKXCAF),
    LibraryProduct("libTKXDEIGES", :libTKXDEIGES),
    LibraryProduct("libTKXDESTEP", :libTKXDESTEP),
    LibraryProduct("libTKXMesh", :libTKXMesh),
    LibraryProduct("libTKXSBase", :libTKXSBase),
    LibraryProduct("libTKXml", :libTKXml),
    LibraryProduct("libTKXmlL", :libTKXmlL),
    LibraryProduct("libTKXmlXCAF", :libTKXmlXCAF),
    LibraryProduct("libTKernel", :libTKernel)
]

# Some dependencies are needed only on Linux and FreeBSD
x11_platforms = filter(p ->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
