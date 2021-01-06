
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
apk add g++ linux-headers samurai gnutls readline musl
export CPPFLAGS="$(pkg-config --cflags glib-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags pango)"
export LDFLAGS="-liconv"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gnuplot", :gnuplot),
    #ExecutableProduct("gnuplot_x11", :gnuplot_x11, "libexec"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Libcerf_jll", uuid="af83a40a-c4c4-57a0-81df-2309fbd279e3")),
    Dependency(PackageSpec(name="LibGD_jll", uuid="16339573-6216-525a-b38f-30b6f6b71b5f")),
    #Dependency(PackageSpec(name="X11_jll", uuid="546b0b6d-9ca3-5ba2-8705-1bc1841d8479")),
    #After WxWidgets has compiled
    #Dependency(PackageSpec(name="WxWidgets_jll", uuid="")),
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")),
    Dependency(PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
