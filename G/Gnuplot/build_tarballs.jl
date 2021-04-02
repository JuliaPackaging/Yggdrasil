
using BinaryBuilder, Pkg

name = "Gnuplot"
version = v"5.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://excellmedia.dl.sourceforge.net/project/gnuplot/gnuplot/$(version)/gnuplot-$(version).tar.gz",
                  "6b690485567eaeb938c26936e5e0681cf70c856d273cc2c45fabf64d8bc6590e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnuplot-*/
# Make uic happy to use `libc.so` ¯\_(ツ)_/¯
apk add g++ linux-headers samurai libgd
export CPPFLAGS="$(pkg-config --cflags glib-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags pango)"
export LDFLAGS="-liconv"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} 
cd src
make -j${nproc}
make install
#make DESTDIR="$WORKSPACE/destdir" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gnuplot", :gnuplot),
    #ExecutableProduct("gnuplot_qt", :gnuplot_qt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    #Dependency(PackageSpec(name="Libcerf_jll", uuid="af83a40a-c4c4-57a0-81df-2309fbd279e3")),
    Dependency(PackageSpec(name="LibGD_jll", uuid="16339573-6216-525a-b38f-30b6f6b71b5f")),
    Dependency(PackageSpec(name="Lua", uuid="a4086b1d-a96a-5d6b-8e4f-2030e6f25ba6")),
    Dependency(PackageSpec(name="Qt5Tools_jll", uuid="a9c6e4b1-b2fb-56d5-96a9-25f276f13840")),
    Dependency(PackageSpec(name="Qt5Svg_jll", uuid="3af4ccab-a251-578e-a514-ea85a0ba79ee")),
    Dependency(PackageSpec(name="Qt5Base_jll", uuid="ea2cea3b-5b76-57ae-a6ef-0a8af62496e1")),
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")),
    Dependency(PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3")),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
