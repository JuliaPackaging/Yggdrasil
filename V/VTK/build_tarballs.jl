using BinaryBuilder, Pkg
using Base.BinaryPlatforms
include(joinpath("..", "..", "platforms", "mpi.jl"))

name = "VTK"
version = v"9.5.2"

# No sources, we're just building the testsuite
sources = [
    ArchiveSource("https://vtk.org/files/release/$(version.major).$(version.minor)/VTK-$(version).tar.gz",
                  "cee64b98d270ff7302daf1ef13458dff5d5ac1ecb45d47723835f7f7d562c989"),
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
               "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/VTK-*

# For the record:
# If we want to build `libproj` ourselves (instead of depending on `PROJ_jll`), then we need the following:
#     apk add sqlite
#
# We also need this patch. (VTK wants to run a target binary. Silly VTK.)
#     --- a/ThirdParty/libproj/vtklibproj/CMakeLists.txt
#     +++ b/ThirdParty/libproj/vtklibproj/CMakeLists.txt
#     @@ -215,7 +215,7 @@
#        message(SEND_ERROR "sqlite3 dependency not found!")
#      endif()
#      else ()
#     -set(EXE_SQLITE3 "$<TARGET_FILE:VTK::sqlitebin>")
#     +set(EXE_SQLITE3 "/usr/bin/sqlite3")
#      set(SQLITE3_FOUND 1)
#      set(SQLITE3_VERSION 3.36.0) # Might be out-of-sync; update as needed.
#      endif ()

# We need a newer libc++
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System
    tar \
        --extract \
        --file=${WORKSPACE}/srcdir/MacOSX10.14.sdk.tar.xz \
        --directory=/opt/${target}/${target}/sys-root/. \
        --strip-components=1 \
        MacOSX10.14.sdk/System \
        MacOSX10.14.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=10.14
fi

if [[ ${target} == *mingw* ]]; then
    apk add sqlite
fi

# Build the tools for building VTK
host_opts=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${host_prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN}
    -DVTK_BUILD_COMPILE_TOOLS_ONLY=ON
)
cmake -Bhost_build -GNinja ${host_opts[@]}
cmake --build host_build --parallel ${nproc}
cmake --install host_build

# For the record:
# If we want to build `hdf5` ourselves (instead of depending on `HDF5_jll`), then we need the following:
#     -DH5_PRINTF_LL_TEST_RUN:STRING=0
#     -DH5_PRINTF_LL_TEST_RUN__TRYRUN_OUTPUT:STRING=9223372036854775807
#     -DH5_LDOUBLE_TO_LONG_SPECIAL=OFF
#     -DH5_LONG_TO_LDOUBLE_SPECIAL=OFF
#     -DH5_LDOUBLE_TO_LLONG_ACCURATE=ON
#     -DH5_LDOUBLE_TO_LLONG_ACCURATE=ON
#     -DH5_LLONG_TO_LDOUBLE_CORRECT=ON
#     -DH5_DISABLE_SOME_LDOUBLE_CONV=OFF
#     -DH5_NO_ALIGNMENT_RESTRICTIONS=OFF

# Build VTK
opts=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DVTK_GENERATE_SPDX=ON
    -DVTK_REQUIRE_LARGE_FILE_SUPPORT=OFF
    -DVTK_USE_MPI=ON
    -DTEST_LFS_WORKS_RUN:STRING=0
    -DVTK_MODULE_USE_EXTERNAL_VTK_cgns=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_expat=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_exprtk=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_hdf5=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_jpeg=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_libharu=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_libproj=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_libxml2=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_lz4=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_lzma=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_netcdf=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_nlohmannjson=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_ogg=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_png=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_pugixml=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_sqlite=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_tiff=ON
    -DVTK_MODULE_USE_EXTERNAL_VTK_zlib=ON
)
if [[ ${target} == *mingw* ]]; then
    opts+=(
        -D_vtk_thread_impl_output=win32
        -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
        -DCMAKE_CXX_VISIBILITY_PRESET=default
        -DCMAKE_VISIBILITY_INLINES_HIDDEN=OFF
    )
fi
cmake -Bbuild -GNinja ${opts[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# To cross-build VTK we need a host architecture with the same bit width as the target architecture.
# Since our host is always a 64-bit architecture we can currently only build for 64-bit target platforms.
# (I guess we could install a 32-bit toolchain on our host if we really wanted to?)
filter!(p -> nbits(p) == 64, platforms)

# We don't support MPItrampoline quite yet
filter!(p -> p["mpi"] != "mpitrampoline", platforms)

# Building on Windows requires GCC 13, and that leads to many follow-up issues.
# Let's try again later.
filter!(!Sys.iswindows, platforms)

# These are all the VTK modules; most have associated shared libraries
vtk_modules = [
    "WrappingTools",
    # "WrapHierarchy",
    # "WrapPython",
    # "WrapPythonInit",
    # "ParseJava",
    # "WrapJava",
    # "WrapSerDes",
    # "kwiml",
    # "vtksys",
    # "nlohmannjson",
    "token",
    # "fast_float",
    "doubleconversion",
    "loguru",
    "CommonCore",
    # "CommonCore-private-kit-links",
    "kissfft",
    "CommonMath",
    "CommonTransforms",
    # "exprtk",
    "CommonMisc",
    "CommonSystem",
    # "CommonSystem-private-kit-links",
    # "pegtl",
    # "pugixml",
    "CommonDataModel",
    "CommonExecutionModel",
    "FiltersReduction",
    "FiltersCore",
    "CommonColor",
    "CommonComputationalGeometry",
    "FiltersGeometry",
    "verdict",
    "FiltersVerdict",
    "fmt",
    "FiltersGeneral",
    "FiltersSources",
    "RenderingCore",
    "FiltersHyperTree",
    # "eigen",
    "FiltersStatistics",
    # "lz4",
    # "lzma",
    # "utf8",
    # "zlib",
    "IOCore",
    "FiltersCellGrid",
    "IOCellGrid",
    "IOLegacy",
    "ParallelCore",
    # "diy2",
    # "expat",
    "IOXMLParser",
    "IOXML",
    "ParallelDIY",
    "FiltersExtraction",
    "InteractionStyle",
    # "freetype",
    "RenderingFreeType",
    "RenderingContext2D",
    "ImagingCore",
    "ImagingSources",
    "FiltersHybrid",
    "FiltersModeling",
    "FiltersTexture",
    "ImagingColor",
    "ImagingGeneral",
    "DICOMParser",
    # "jpeg",
    "metaio",
    # "png",
    # "tiff",
    "IOImage",
    "ImagingHybrid",
    "RenderingAnnotation",
    "RenderingVolume",
    "InteractionWidgets",
    "glad",
    "RenderingUI",
    "ViewsCore",
    "InfovisCore",
    "ChartsCore",
    "FiltersImaging",
    "InfovisLayout",
    # "octree",
    "RenderingLabel",
    "ViewsInfovis",
    "ViewsContext2D",
    "TestingCore",
    "TestingRendering",
    "RenderingLOD",
    "RenderingHyperTreeGrid",
    "RenderingOpenGL2",
    # "RenderingOpenGL2-private-kit-links",
    # "vtkProbeOpenGLVersion",
    "RenderingLICOpenGL2",
    "RenderingImage",
    "RenderingGridAxes",
    "RenderingContextOpenGL2",
    "RenderingCellGrid",
    "ImagingMath",
    "RenderingVolumeOpenGL2",
    # "vtkhdf5_src",
    # "vtkhdf5_hl_src",
    # "hdf5",
    "IOVeraOut",
    "IOTecplotTable",
    "IOSegY",
    "IOParallelXML",
    "IOPLY",
    "IOMovie",
    # "ogg",
    "theora",
    "IOOggTheora",
    # "netcdf",
    "IONetCDF",
    "IOGeometry",
    "IOMotionFX",
    "jsoncpp",
    "FiltersParallel",
    "IOParallel",
    "IOMINC",
    "IOLSDyna",
    "IOLANLX3D",
    "IOImport",
    # "cgns",
    "exodusII",
    # "ioss",
    # "IOIOSS",
    # "IOHDFTools",
    "FiltersTemporal",
    "IOHDF",
    "IOFLUENTCFF",
    "IOVideo",
    # "libxml2",
    "IOInfovis",
    "IOFDS",
    "RenderingSceneGraph",
    "RenderingVtkJS",
    "DomainsChemistry",
    "IOExport",
    # "libharu",
    "IOExportPDF",
    "gl2ps",
    "RenderingGL2PSOpenGL2",
    "IOExportGL2PS",
    "IOExodus",
    "IOEngys",
    "IOEnSight",
    "IOERF",
    "IOCityGML",
    "IOChemistry",
    # "sqlite",
    # "libproj",
    "IOCesium3DTiles",
    "IOCONVERGECFD",
    # "IOCGNSReader",
    "IOAsynchronous",
    "FiltersAMR",
    "IOAMR",
    "InteractionImage",
    "ImagingStencil",
    "ImagingStatistics",
    "ImagingMorphological",
    "ImagingFourier",
    "IOSQL",
    "GeovisCore",
    "FiltersTopology",
    "FiltersTensor",
    "FiltersSelection",
    "FiltersSMP",
    "FiltersProgrammable",
    "FiltersPoints",
    "FiltersParallelImaging",
    "FiltersGeometryPreview",
    "FiltersGeneric",
    "FiltersFlowPaths",
    # [there but not found on darwin?] "DomainsChemistryOpenGL2",
]

# The products that we will ensure are always built
products = [
    # The MacOS library names we specify here cannot end in `.digit`. These are interpreted as soversion by BinaryBuilder.
    # The Windows library names we specify here cannot end in `-digit.digit`. These are interpreted as soversion by BinaryBuilder.
    # Note: When the auditor fails on x86_64-linux because GCC 13 is too new then we can work around this via `dont_dlopen=true`.
    [LibraryProduct(["libvtk$(mod)-$(version.major).$(version.minor)", "libvtk$(mod)-$(version.major)", "libvtk$(mod)"],
                    Symbol("libvtk$(mod)")) for mod in vtk_modules];
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CGNS_jll"; compat="4.5.0"),           # cgns
    Dependency("Expat_jll"; compat="2.7.1"),          # expat
    Dependency("FreeType2_jll"; compat="2.13.4"),     # freetype
    Dependency("HDF5_jll"; compat="~1.14.6"),         # hdf5
    Dependency("JpegTurbo_jll"; compat="3.1.2"),      # jpeg
    Dependency("Libtiff_jll"; compat="4.7.1"),        # tiff
    Dependency("Lz4_jll"; compat="1.10.1"),           # lz4
    Dependency("NetCDF_jll"; compat="401.900.300"),   # netcdf
    Dependency("Ogg_jll"; compat="1.3.6"),            # ogg
    Dependency("PROJ_jll"; compat="902.600.200"),     # libproj
    Dependency("SQLite_jll"; compat="3.48.0"),        # sqlite
    Dependency("XML2_jll"; compat="~2.13.6"),         # libxml2
    Dependency("XZ_jll"; compat="5.8.1"),             # lzma
    Dependency("Zlib_jll"; compat="1.2.12"),          # zlib
    Dependency("exprtk_jll"; compat="0.0.3"),         # exprtk
    Dependency("libharu_jll"; compat="2.4.5"),        # libharu
    Dependency("libpng_jll"; compat="1.6.50"),        # png
    Dependency("nlohmann_json_jll"; compat="3.12.0"), # nlohmannjson
    Dependency("pugixml_jll"; compat="1.14.1"),       # pugixmi

    # osmesa (Mesa_jll; support all architectures)

    # We need some X11 libraries. I don't know which ones exactly so I list all of them here. That's probably overkill.
    BuildDependency("Xorg_compositeproto_jll"),
    BuildDependency("Xorg_damageproto_jll"),
    BuildDependency("Xorg_dri2proto_jll"),
    BuildDependency("Xorg_dri3proto_jll"),
    BuildDependency("Xorg_fixesproto_jll"),
    BuildDependency("Xorg_glproto_jll"),
    BuildDependency("Xorg_inputproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_randrproto_jll"),
    BuildDependency("Xorg_recordproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xcb_proto_jll"),
    BuildDependency("Xorg_xextproto_jll"),
    BuildDependency("Xorg_xf86vidmodeproto_jll"),
    BuildDependency("Xorg_xineramaproto_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Xorg_libICE_jll"),
    Dependency("Xorg_libSM_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXScrnSaver_jll"),
    Dependency("Xorg_libXau_jll"),
    Dependency("Xorg_libXcomposite_jll"),
    Dependency("Xorg_libXcursor_jll"),
    Dependency("Xorg_libXdamage_jll"),
    Dependency("Xorg_libXdmcp_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXfixes_jll"),
    Dependency("Xorg_libXft_jll"),
    Dependency("Xorg_libXi_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Xorg_libXmu_jll"),
    Dependency("Xorg_libXpm_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libXrender_jll"),
    Dependency("Xorg_libXt_jll"),
    Dependency("Xorg_libXtst_jll"),
    Dependency("Xorg_libXxf86vm_jll"),
    Dependency("Xorg_libpciaccess_jll"),
    Dependency("Xorg_libpthread_stubs_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_libxkbfile_jll"),
    Dependency("Xorg_libxshmfence_jll"),
    Dependency("Xorg_scrnsaverproto_jll"),
    Dependency("Xorg_xcb_util_cursor_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
    Dependency("Xorg_xcb_util_jll"),
    Dependency("Xorg_xcb_util_keysyms_jll"),
    Dependency("Xorg_xcb_util_renderutil_jll"),
    Dependency("Xorg_xcb_util_wm_jll"),
    Dependency("Xorg_xkbcomp_jll"),
    Dependency("Xorg_xkeyboard_config_jll"),
    Dependency("Xorg_xtrans_jll"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs.
# VTK requires GCC 8
# We would need GCC 13 on Windows for the new `[[...]]`` attribute syntax.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
