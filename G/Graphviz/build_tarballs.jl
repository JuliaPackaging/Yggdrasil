# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Graphviz"
version = v"2.49.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/$(version)/graphviz-$(version).tar.gz",
                  "f79b203ddc98e0f994d218acd6cb490b962003be7145f7e31de05b6ab0e2ccbf"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphviz-*/

if [[ "${target}" == *-mingw* ]]; then
    # We need a `regex.h` header.  MinGW doesn't have one,
    # let's use `pcreposix.h` instead.
    cp ${prefix}/include/pcreposix.h ${prefix}/include/regex.h

    export LDFLAGS="-lpcreposix -lexpat"
    export EXTRA_LDFLAGS="-no-undefined"

    # Remove wrong libtool archives
    #rm ${prefix}/lib/libharfbuzz*.la
fi

# Do not build with -ffast-math
atomic_patch -p1 ../patches/1001-no-ffast-math.patch
atomic_patch -p1 ../patches/0001-windows-exports.patch
atomic_patch -p1 ../patches/0003-gvc-def.patch

# Rebuild the configure script
autoreconf -fiv

# This patch disable generation of dot's configuration
atomic_patch -p1 ../patches/0002-do-not-build-dot-config.patch

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared

make -j${nproc} LDFLAGS="${LDFLAGS} ${EXTRA_LDFLAGS}"
make install

if [[ "${target}" == *-mingw* ]]; then
    # Cover up the traces of the hack
    rm ${prefix}/include/regex.h
fi

if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
    cp ../config6-linux ${prefix}/lib/graphviz/config6
elif [[ "${target}" == *-mingw* ]]; then
    cp ../config6-mingw ${prefix}/bin/config6
elif [[ "${target}" == *-darwin* ]]; then
    cp ../config6-darwin ${prefix}/lib/graphviz/config6
fi

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcdt", :libcdt),
    LibraryProduct("libcgraph", :libcgraph),
    LibraryProduct("libgvc", :libgvc),
    LibraryProduct("libgvpr", :libgvpr),
    LibraryProduct("liblab_gamut", :liblab_gamut),
    LibraryProduct("libpathplan", :libpathplan),
    LibraryProduct("libxdot", :libxdot),
    ExecutableProduct("acyclic", :acyclic),
    ExecutableProduct("bcomps", :bcomps),
    ExecutableProduct("ccomps", :ccomps),
    ExecutableProduct("circo", :circo),
    ExecutableProduct("cluster", :cluster),
    ExecutableProduct("dijkstra", :dijkstra),
    ExecutableProduct("dot", :dot),
    ExecutableProduct("dot2gxl", :dot2gxl),
    ExecutableProduct("dot_builtins", :dot_builtins),
    ExecutableProduct("edgepaint", :edgepaint),
    ExecutableProduct("fdp", :fdp),
    ExecutableProduct("gc", :gc),
    ExecutableProduct("gml2gv", :gml2gv),
    ExecutableProduct("graphml2gv", :graphml2gv),
    ExecutableProduct("gv2gml", :gv2gml),
    ExecutableProduct("gv2gxl", :gv2gxl),
    ExecutableProduct("gvcolor", :gvcolor),
    ExecutableProduct("gvgen", :gvgen),
    ExecutableProduct("gvmap", :gvmap),
    #ExecutableProduct("gvmap.sh", :gvmap_sh),
    ExecutableProduct("gvpack", :gvpack),
    ExecutableProduct("gvpr", :gvpr),
    ExecutableProduct("gxl2dot", :gxl2dot),
    ExecutableProduct("gxl2gv", :gxl2gv),
    ExecutableProduct("mm2gv", :mm2gv),
    ExecutableProduct("neato", :neato),
    ExecutableProduct("nop", :nop),
    ExecutableProduct("osage", :osage),
    ExecutableProduct("patchwork", :patchwork),
    ExecutableProduct("prune", :prune),
    ExecutableProduct("sccmap", :sccmap),
    ExecutableProduct("sfdp", :sfdp),
    ExecutableProduct("tred", :tred),
    ExecutableProduct("twopi", :twopi),
    ExecutableProduct("unflatten", :unflatten),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")),
    Dependency("Expat_jll", v"2.2.7"; compat="~2.2.7"),
    Dependency("Pango_jll", v"1.42.4"; compat="1.42.4"),
    # PCRE is needed only for Windows.  Maybe it's only a build dependency?
    # Dependency(PackageSpec(name="PCRE_jll",  uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc")),
    # Indirect dependency from pango, but without this, pkg-config doesn't pick up pango
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
