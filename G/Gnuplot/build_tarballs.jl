
using BinaryBuilder, Pkg

name = "Gnuplot"
version = v"6.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/gnuplot/gnuplot/$(version)/gnuplot-$(version).tar.gz",
                  "ec52e3af8c4083d4538152b3f13db47f6d29929a3f6ecec5365c834e77f251ab"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnuplot-*/

echo target=${target}
# set

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Delete system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
elif [[ "${target}" == *-mingw* ]]; then
    # This is needed because otherwise we get unusable binaries (error "The specified executable is not a valid application for this OS platform").
    # Apply patch from https://github.com/msys2/MINGW-packages/blob/5dcff9fd637714972b113c6d3fbf6db17e9b707a/mingw-w64-gnuplot/01-gnuplot.patch
    atomic_patch -p1 ../patches/01-gnuplot.patch
    autoreconf -fiv
fi

# export CPPFLAGS="$(pkg-config --cflags glib-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags pango) -I$(realpath term)"
export LIBS='-liconv'

unset args
args+=(--disable-wxwidgets)

# FIXME: no Qt artifacts available for these platforms
if [[ "${target}" == *-musl* ]] || [[ "${target}" == *-freebsd ]] || [[ "${target}" == riscv64-linux-gnu ]]; then
    args+=(--with-qt=no)
fi

# if [[ "${target}" == riscv64-linux-gnu ]]; then  # FIXME: failure, see maybe https://sourceforge.net/p/gnuplot/bugs/2591
#     export CXXFLAGS='-std=c++11 -I/workspace/destdir/include/QtCore'
# fi

./configure --help

echo ${args[@]}
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${args[@]}


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
    # ExecutableProduct("gnuplot_qt", :gnuplot_qt, "$libexecdir")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("libwebp_jll"),
    Dependency("Libcerf_jll"),
    Dependency("LibGD_jll"),
    Dependency("Cairo_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Readline_jll"),
    BuildDependency("Qt5Tools_jll"),
    # Dependency("Qt5Base_jll"),
    Dependency("Qt5Svg_jll"),
    # FIXME: qt6 fails (missing uic)
    # Dependency("Qt6Base_jll"),
    # Dependency("Qt6Svg_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
