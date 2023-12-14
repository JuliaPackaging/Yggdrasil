# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Poppler"
version = v"23.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://poppler.freedesktop.org/poppler-$(version).tar.xz",
                  "beba398c9d37a9b6d02486496635e08f1df3d437cfe61dab2593f47c4d14cdbb")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/poppler-*

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
fi

# cmake doesn't find FreeType2 without help
export FREETYPE_DIR=${prefix}

cmake -B build \
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

# `armv6l` is not supported, `libpoppler_glib` is not built
filter!(p -> arch(p) != "armv6l", platforms)

# C++03 is not supported because
# `error: function ‘GfxFontLoc& GfxFontLoc::operator=(GfxFontLoc&&)’ defaulted on its redeclaration with an exception-specification that differs from the implicit exception-specification`
filter!(p -> cxxstring_abi(p) != "cxx03", platforms)

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
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Cairo_jll"; compat="1.16.1"), # we need 1.16.0
    Dependency("Fontconfig_jll"),             # we need 2.12
    Dependency("FreeType2_jll"),              # we need 2.10
    Dependency("Glib_jll"; compat="2.68.1"),  # we need 2.64
    Dependency("JpegTurbo_jll"),
    Dependency("LibCURL_jll"; compat="7.73,8"),# we need 7.68
    Dependency("Libtiff_jll"; compat="4.5.1"), # we need 4.1
    Dependency("OpenJpeg_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 8 since we need C++17 (`std::string_view` and `<charconv>`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
