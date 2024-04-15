# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "zbar"
version = v"0.23.93"

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://github.com/mchehab/zbar.git", "bb05ec54eec57f8397cb13fb9161372a281a1219"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zbar
if [[ "${target}" != "*mingw32*" ]]; then
    # install `autopoint`
    apk update && apk add gettext-dev
fi
install_license COPYING LICENSE.md
autoreconf -vfi
update_configure_scripts
./configure --with-x=disabled \
            --enable-pthread=yes \
            --enable-video=no \
            --with-jpeg=no \
            --with-imagemagick=yes \
            --with-python=no \
            --with-gtk=no \
            --with-qt=no \
            --prefix=${prefix} \
            --build=${MACHTYPE} \
            --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libzbar", :libzbar),
    ExecutableProduct("zbarimg", :zbarimg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ImageMagick_jll", uuid="c73af94c-d91f-53ed-93a7-00f77d67a9d7"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"); platforms=filter(!Sys.isapple, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
