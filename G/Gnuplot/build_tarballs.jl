
using BinaryBuilder, Pkg

name = "Gnuplot"
version = v"5.4.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/gnuplot/gnuplot/$(version)/gnuplot-$(version).tar.gz",
                  "66f679115dd30559e110498fc94d926949d4d370b4999a042e724b8e910ee478"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnuplot-*/


if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Delete system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
elif [[ "${target}" == *-mingw* ]]; then
    # This is needed because otherwise we get unusable binaries (error "The specified executable is not a valid application for this OS platform"). These come from CompilerSupportLibraries_jll:
    rm $prefix/lib/libgcc* $prefix/lib/libmsvcrt*
    # Apply patch from https://github.com/msys2/MINGW-packages/blob/5dcff9fd637714972b113c6d3fbf6db17e9b707a/mingw-w64-gnuplot/01-gnuplot.patch
    atomic_patch -p1 ../patches/01-gnuplot.patch
    autoreconf -fiv
fi

export CPPFLAGS="$(pkg-config --cflags glib-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags pango) -I$(realpath term)"
export LDFLAGS="-liconv"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
cd src
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gnuplot", :gnuplot),
    #ExecutableProduct("gnuplot_qt", :gnuplot_qt, "$libexecdir")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Libcerf_jll", uuid="af83a40a-c4c4-57a0-81df-2309fbd279e3")),
    Dependency(PackageSpec(name="LibGD_jll", uuid="16339573-6216-525a-b38f-30b6f6b71b5f")),
    BuildDependency(PackageSpec(name="Qt5Tools_jll", uuid="a9c6e4b1-b2fb-56d5-96a9-25f276f13840")),
    Dependency(PackageSpec(name="Qt5Svg_jll", uuid="3af4ccab-a251-578e-a514-ea85a0ba79ee")),
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
