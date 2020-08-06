# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Graphviz"
version = v"2.42.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www2.graphviz.org/Packages/stable/portable_source/graphviz-$(version).tar.gz",
                  "8faf3fc25317b1d15166205bf64c1b4aed55a8a6959dcabaa64dbad197e47add"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphviz-*/

if [[ "${target}" == *-mingw* ]]; then
    # We need a `regex.h` header.  MinGW doesn't have one,
    # let's use `pcreposix.h` instead.
    cp ${prefix}/include/pcreposix.h ${prefix}/include/regex.h

    # Apply some fun patches
    atomic_patch -p1 ../patches/0003-sfsetbuf_c_Stat_t_no_st_blksize.patch
    atomic_patch -p1 ../patches/0004-win32_dllexport_dllimport.patch
    atomic_patch -p1 ../patches/0005-missing_libs.patch
    atomic_patch -p1 ../patches/0006-export_neatogen.patch
    atomic_patch -p1 ../patches/0007-remove_missing_def.patch
    atomic_patch -p1 ../patches/0008-export_gvc.patch

    export LDFLAGS="-lpcreposix -lexpat"
    export EXTRA_LDFLAGS="-no-undefined"

    # Remove wrong libtool archives
    rm ${prefix}/lib/libharfbuzz*.la
fi

# Do not build with -ffast-math
atomic_patch -p1 ../patches/1001-no-ffast-math.patch

# Rebuild the configure script
autoreconf -fiv

# Apply patch to build a native `mkdefs` utility that can be run within the
# build environment.
atomic_patch -p1 ../patches/0001-gvpr-build-native-mkdefs.patch

# This patch disable generation of dot's configuration
atomic_patch -p1 ../patches/0002-do-not-build-dot-config.patch

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} LDFLAGS="${LDFLAGS} ${EXTRA_LDFLAGS}"
make install

if [[ "${target}" == *-mingw* ]]; then
    # Cover up the traces of the hack
    rm ${prefix}/include/regex.h
fi

${bindir}/dot -c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(p -> !isa(p, FreeBSD) & !isa(p, Windows), supported_platforms()))

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
    ExecutableProduct("gvmap.sh", :gvmap_sh),
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
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201")),
    Dependency(PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3")),
    # PCRE is needed only for Windows.  Maybe it's only a build dependency?
    # Dependency(PackageSpec(name="PCRE_jll",  uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
