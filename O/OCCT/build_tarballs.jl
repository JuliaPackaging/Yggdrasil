# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "OCCT"
version = v"8.0.2"

# Collection of sources required to build Open CASCADE Technology (OCCT)
sources = [
    GitSource("https://github.com/Open-Cascade-SAS/OCCT.git",
              "83f9abe9477af36e4ca218e1468068aed052779f";
              tag="V$(version.major)_$(version.minor)_$(version.patch)"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OCCT
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_limits_noexcept.patch"
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
    -DBUILD_MODULE_ApplicationFramework=0 \
    -DUSE_RAPIDJSON=ON \
    -D3RDPARTY_RAPIDJSON_INCLUDE_DIR=${includedir}
make -j${nproc}
make install
install_license ../LICENSE_LGPL_21.txt ../OCCT_LGPL_EXCEPTION.txt
"""

# std::variant's throwing accessors need libc++ from macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

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
    LibraryProduct("libTKDEIGES", :libTKDEIGES),
    LibraryProduct("libTKDEGLTF", :libTKDEGLTF),
    LibraryProduct("libTKDEOBJ", :libTKDEOBJ),
    LibraryProduct("libTKDEPLY", :libTKDEPLY),
    LibraryProduct("libTKDESTEP", :libTKDESTEP),
    LibraryProduct("libTKDESTL", :libTKDESTL),
    LibraryProduct("libTKDEVRML", :libTKDEVRML),
    LibraryProduct("libTKFeat", :libTKFeat),
    LibraryProduct("libTKFillet", :libTKFillet),
    LibraryProduct("libTKG2d", :libTKG2d),
    LibraryProduct("libTKG3d", :libTKG3d),
    LibraryProduct("libTKGeomAlgo", :libTKGeomAlgo),
    LibraryProduct("libTKGeomBase", :libTKGeomBase),
    LibraryProduct("libTKHLR", :libTKHLR),
    LibraryProduct("libTKLCAF", :libTKLCAF),
    LibraryProduct("libTKMath", :libTKMath),
    LibraryProduct("libTKMesh", :libTKMesh),
    LibraryProduct("libTKOffset", :libTKOffset),
    LibraryProduct("libTKPrim", :libTKPrim),
    LibraryProduct("libTKRWMesh", :libTKRWMesh),
    LibraryProduct("libTKService", :libTKService),
    LibraryProduct("libTKShHealing", :libTKShHealing),
    LibraryProduct("libTKTopAlgo", :libTKTopAlgo),
    LibraryProduct("libTKV3d", :libTKV3d),
    LibraryProduct("libTKVCAF", :libTKVCAF),
    LibraryProduct("libTKXCAF", :libTKXCAF),
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
    # Header-only, for the glTF reader and writer in TKDEGLTF
    BuildDependency("rapidjson_jll"),
    # libgcc_s. Julia 1.6 ships 0.5.0 and 1.8 ships 1.0.1; build against 1.1.2,
    # the oldest release with a riscv64 build
    Dependency("CompilerSupportLibraries_jll", v"1.1.2";
               compat="0.5.0, 1",
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency("FreeType2_jll"; compat="2.13.4"),
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
