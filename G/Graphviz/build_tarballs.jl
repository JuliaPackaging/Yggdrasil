# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Graphviz"
version = v"15.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/$(version)/graphviz-$(version).tar.gz",
                  "7aee43f186d6d72d32cbdb243baaa98880d4e709a2937c1ccf0dcc61abd79ec2"),

    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphviz-*/

if [[ "${target}" == *-mingw* ]]; then
    export LDFLAGS="-lexpat"
    export EXTRA_LDFLAGS="-no-undefined"
elif [[ "${target}" == *-linux* ]]; then
    # ld needs -rpath-link to resolve the DT_NEEDEDs of the libraries the
    # executables link against (it does not search libtool's -rpath
    # entries, and on x86_64-musl the fallback finds the host's
    # incompatible /usr/lib libraries)
    LDFLAGS="-Wl,-rpath-link,${libdir}"
    for d in cdt pathplan xdot cgraph gvc; do
        LDFLAGS="${LDFLAGS} -Wl,-rpath-link,$(pwd)/lib/${d}/.libs"
    done
    export LDFLAGS
elif [[ "${target}" == *-darwin* ]]; then
    # Paired with the @rpath install names set below; the second entry lets
    # dot_builtins find the plugin dylibs it links directly
    export LDFLAGS="-Wl,-rpath,@loader_path/../lib -Wl,-rpath,@loader_path/../lib/graphviz"
fi

# ld64.lld's deprecation warning for -single_module makes libtool's probe
# fail, degrading its C++ dylib support; pre-seed the correct answer
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared \
    lt_cv_apple_cc_single_mod=yes

if [[ "${target}" == *-darwin* ]]; then
    # Use @rpath install names so the auditor does not need to rewrite the
    # installed binaries. Our executables link 5-7 internal dylibs each,
    # which reliably trips a race in the auditor's rewrite path; see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/pull/1442
    sed -i 's|-install_name [\\]*\$rpath/|-install_name @rpath/|g' libtool
    grep -q -- '-install_name @rpath/' libtool
fi

make -j${nproc} LDFLAGS="${LDFLAGS} ${EXTRA_LDFLAGS}"
make install

# `dot -c` cannot be run during a cross-compilation, so ship a pregenerated
# plugin config (config$GVPLUGIN_CURRENT, currently config8).
if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
    install -Dvm 755 ../config8-linux ${prefix}/lib/graphviz/config8
elif [[ "${target}" == *-mingw* ]]; then
    install -Dvm 755 ../config8-mingw ${prefix}/bin/config8
elif [[ "${target}" == *-darwin* ]]; then
    install -Dvm 755 ../config8-darwin ${prefix}/lib/graphviz/config8
fi

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcdt", :libcdt),
    LibraryProduct("libcgraph", :libcgraph),
    LibraryProduct("libgvc", :libgvc),
    LibraryProduct("libgvpr", :libgvpr),
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
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Pango_jll"; compat="1.47.0"),
    # For the svgz and kittyz compressed output devices
    Dependency("Zlib_jll"),
    # PCRE is needed only for Windows.  Maybe it's only a build dependency?
    # Dependency(PackageSpec(name="PCRE_jll",  uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc")),
    # Indirect dependency from pango, but without this, pkg-config doesn't pick up pango
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 10 for the C++17 features required since Graphviz 13
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
