# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Poppler"
version = v"0.87.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://poppler.freedesktop.org/poppler-0.87.0.tar.xz", "6f602b9c24c2d05780be93e7306201012e41459f289b8279a27a79431ad4150e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/poppler-*/

# Create link ${bindir} before starting.  `OpenJPEGTargets.cmake` will try to
# look for some executables in `sys-root/usr/local/bin`
ln -s ${bindir} /opt/${target}/${target}/sys-root/usr/local/bin
export CXXFLAGS="-I${prefix}/include/openjpeg-2.3"

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_GTK_TESTS=OFF \
    -DENABLE_CMS=lcms2 \
    -DENABLE_GLIB=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DWITH_GObjectIntrospection=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libpoppler-cpp", :libpoppler_cpp),
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
    Dependency("JpegTurbo_jll"),
    Dependency("Cairo_jll"),
    #Dependency("gdk_pixbuf_jll"),
    #Dependency("GTK3_jll"),
    Dependency("Libtiff_jll"),
    Dependency("libpng_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Fontconfig_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
