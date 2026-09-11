# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OCCT"
version = v"8.0.0"

# Collection of sources required to build Open CASCADE Technology (OCCT)
sources = [
    GitSource("https://github.com/Open-Cascade-SAS/OCCT.git",
              "4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d"), # V8_0_0_p1 @ Jun 17, 2026
    DirectorySource("./bundled"),
    # The bundled x86_64-apple-darwin SDK is too old to have symbols (e.g.
    # std::bad_variant_access) needed by OCCT's C++17 std library usage.
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
                  "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OCCT
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_Real.hxx.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Standard_Integer.hxx.patch"
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
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    # OCCT now uses std::shared_mutex (macOS 10.12+), std::variant/std::visit
    # (macOS 10.14+), and objc_alloc_init (a newer ObjC runtime helper) in its
    # Cocoa bridging code. The bundled SDK's linker stubs (usr/lib/*.tbd)
    # simply predate these symbols entirely (missing regardless of deployment
    # target), so replace all of them with the newer SDK's flat, individual
    # stub files. Deliberately *not* swapping System/Library/Frameworks (as
    # e.g. Trilinos's build_tarballs.jl does for a different symbol): that
    # directory tree is a maze of Versions/Current-style symlinks, and doing
    # so once made BinaryBuilder's post-build audit hang for over an hour,
    # apparently while resolving a broken symlink left behind by a partial
    # `rm -rf`. usr/lib/*.tbd are flat text stub files with no such risk.
    cp -a ${WORKSPACE}/srcdir/MacOSX11.*.sdk/usr/lib/*.tbd \
          "/opt/${target}/${target}/sys-root/usr/lib/"
    export MACOSX_DEPLOYMENT_TARGET=10.15
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
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("rapidjson_jll"; compat="1.1.1"),
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
