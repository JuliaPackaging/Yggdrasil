# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GTKmm3"
version = v"3.24.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/gtkmm/$(version.major).$(version.minor)/gtkmm-$(version).tar.xz",
                  "1d7a35af9c5ceccacb244ee3c2deb9b245720d8510ac5c7e6f4b6f9947e6789c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtkmm*/


#= The following is taken directly from Yggdrasil's GTK3 recipe =#

# We need to run some commands with a native Glib
apk add glib-dev gtk+3.0

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${prefix}/bin/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${prefix}/bin/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${prefix}/bin/gdk-pixbuf-pixdata


#= Back to the actual build =#
mkdir output && cd output
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson .. -Dbuild-demos=false -Dbuild-tests=false
ninja -j${nproc}
ninja install

# Remove temporary links
rm ${bindir}/gdk-pixbuf-pixdata ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(); skip=Returns(true))

# These platforms are not supported by Cairo_jll/Pango_jll yet
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

platforms = expand_cxxstring_abis(platforms; skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgtkmm-3", "libgtkmm-3.0"], :libgtkmm3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairomm_jll", uuid="af74c99f-f0eb-54aa-aecc-a10e8fc65c17"); compat="~1.14.4")
    Dependency(PackageSpec(name="Glibmm_jll", uuid="5d85a9da-21f7-5855-afec-cdc5039c46e8"); compat="~2.66.6")
    Dependency(PackageSpec(name="Pangomm_jll", uuid="9c53b654-4175-57d2-a160-8980ed551c15"); compat="~2.46.3")
    Dependency(PackageSpec(name="ATKmm_jll", uuid="ae83496e-abbd-5b27-8e4c-ced0103e1cfe"); compat="~2.28.3")
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"); compat="^3.24.31")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
