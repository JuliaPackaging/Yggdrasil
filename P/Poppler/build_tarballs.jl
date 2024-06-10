# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Poppler"
version_str = "24.06.0"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://poppler.freedesktop.org/poppler-$(version_str).tar.xz",
                  "0cdabd495cada11f6ee9e75c793f80daf46367b66c25a63ee8c26d0f9ec40c76"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/poppler-*

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

export PATH=${host_bindir}:${PATH}

# cmake doesn't find FreeType2 without help
export FREETYPE_DIR=${prefix}

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_CPP_TESTS=OFF \
    -DBUILD_GTK_TESTS=OFF \
    -DBUILD_MANUAL_TESTS=OFF \
    -DBUILD_QT5_TESTS=OFF \
    -DBUILD_QT6_TESTS=OFF \
    -DENABLE_BOOST=OFF \
    -DENABLE_CMS=lcms2 \
    -DENABLE_GLIB=ON \
    -DENABLE_GPGME=OFF \
    -DENABLE_NSS3=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_QT6=OFF \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DWITH_GObjectIntrospection=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libpoppler-cpp", :libpoppler_cpp),
    LibraryProduct("libpoppler-glib", :libpoppler_glib),
    LibraryProduct("libpoppler", :libpoppler),
    ExecutableProduct("pdfattach", :pdfattach),
    ExecutableProduct("pdfdetach", :pdfdetach),
    ExecutableProduct("pdffonts", :pdffonts),
    ExecutableProduct("pdfimages", :pdfimages),
    ExecutableProduct("pdfinfo", :pdfinfo),
    ExecutableProduct("pdfseparate", :pdfseparate),
    ExecutableProduct("pdftocairo", :pdftocairo),
    ExecutableProduct("pdftohtml", :pdftohtml),
    ExecutableProduct("pdftoppm", :pdftoppm),
    ExecutableProduct("pdftops", :pdftops),
    ExecutableProduct("pdftotext", :pdftotext),
    ExecutableProduct("pdfunite", :pdfunite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec("CMake_jll", v"3.22.2")), # we need 3.22.0
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Cairo_jll"; compat="1.18.0"),       # we need 1.16.0
    Dependency("Fontconfig_jll"; compat="2.13.93"), # we need 2.13
    Dependency("FreeType2_jll"; compat="2.13.1"),   # we need 2.11
    Dependency("Glib_jll"; compat="2.74.0"),        # we need 2.72
    Dependency("JpegTurbo_jll"; compat="3.0.1"),
    Dependency("LibCURL_jll"; compat="7.73,8"), # we need 7.68
    Dependency("Libtiff_jll"; compat="4.6.0"),  # we need 4.3
    Dependency("OpenJpeg_jll";compat="2.5.0"),
    Dependency("libpng_jll"; compat="1.6.38"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 10 since we need modern C++17 (`std::string_view`, `<charconv>`, and `<span>`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
