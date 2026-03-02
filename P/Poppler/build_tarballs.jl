# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Poppler"
version_str = "25.10.0"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://poppler.freedesktop.org/poppler-$(version_str).tar.xz",
                  "6b5e9bb64dabb15787a14db1675291c7afaf9387438cc93a4fb7f6aec4ee6fe0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/poppler-*

apk del cmake

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
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

sources, script = require_macos_sdk("14.5", sources, script; deployment_target="11")

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
# https://gitlab.freedesktop.org/poppler/poppler/-/blob/poppler-25.10.0/CMakeLists.txt?ref_type=tags#L146-157
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.22.2")), # we need 3.22.0
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Cairo_jll"; compat="1.18.5"),       # we need 1.16.0
    Dependency("Fontconfig_jll"; compat="2.16"), # we need 2.13
    Dependency("FreeType2_jll"; compat="2.13.4"),   # we need 2.11
    Dependency("Glib_jll"; compat="2.84.0"),        # we need 2.72
    Dependency("JpegTurbo_jll"; compat="3.1.1"),
    Dependency("LibCURL_jll"; compat="7.81,8"), # we need 7.81
    Dependency("Libtiff_jll"; compat="4.7.1"),  # we need 4.3
    Dependency("OpenJpeg_jll";compat="2.5.4"),
    Dependency("libpng_jll"; compat="1.6.47"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 11 since we need modern C++20 (including `std::ranges`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
