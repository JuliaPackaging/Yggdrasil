# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XicTools"
version = v"4.3.23"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wrcad/xictools",
              "a51c6b6386ad923b9da4e66d11513dc2e0fe3997"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xictools/
cp Makefile.sample Makefile
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/malloc-2.8.6.c.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/Makefile.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/local_malloc-free-init.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/vardb-stdc-format-macros.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/hcimlib-no-x11.patch
update_configure_scripts
make config
make all
install -d ${prefix}/xictools/bin
make INSTALL_PREFIX=${prefix} install
install -m755 wrspice/bin/wrspice ${prefix}/xictools/wrspice.current/bin/wrspice
rm -f ${prefix}/xictools/wrspice.current/bin/wrspice.sh
rm -f ${prefix}/xictools/bin/wrspice
mkdir -p ${bindir}
cd ${prefix}
for tool in wrspice wrspiced csvtoraw multidec printtoraw mmjco; do
    mv xictools/wrspice.current/bin/${tool} ${bindir}/${tool}
    ln -sfn ../../../bin/${tool} xictools/wrspice.current/bin/${tool}
done
for tool in admsXml vl busgen capgen cubegen fastcap fasthenry fcpp lstpack lstunpack mrouter pipedgen pyragen zbuf; do
    mv xictools/bin/${tool} ${bindir}/${tool}
    ln -sfn ../../bin/${tool} xictools/bin/${tool}
done
for tool in wrspice wrspiced csvtoraw multidec printtoraw mmjco; do
    ln -sfn ../wrspice.current/bin/${tool} xictools/bin/${tool}
done
ln -sfn wrspice.current xictools/wrspice
install_license ${WORKSPACE}/srcdir/xictools/license/LICENSE-2.0.txt
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# Linux builds only for now. Windows and MacOS builds possible
# but those require a different set of commands and tooling. 
# See https://github.com/wrcad/xictools/blob/master/README
platforms = [Platform("x86_64", "linux")]

# Contains std::string values!  This causes incompatibilities across
# the GCC 4/5 version boundary. To remedy this, you must build a
# tarball for both GCC 4 and GCC 5.  To do this, immediately after
# your `platforms` definition in your `build_tarballs.jl` file, 
# add the line: platforms = expand_cxxstring_abis(platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mmjco", :mmjco),
    ExecutableProduct("multidec", :multidec),
    ExecutableProduct("printtoraw", :printtoraw),
    ExecutableProduct("wrspice", :wrspice),
    ExecutableProduct("wrspiced", :wrspiced),
    ExecutableProduct("admsXml", :admsXml),
    ExecutableProduct("busgen", :busgen),
    ExecutableProduct("capgen", :capgen),
    ExecutableProduct("cubegen", :cubegen),
    ExecutableProduct("fastcap", :fastcap),
    ExecutableProduct("fasthenry", :fasthenry),
    ExecutableProduct("fcpp", :fcpp),
    ExecutableProduct("lstpack", :lstpack),
    ExecutableProduct("lstunpack", :lstunpack),
    ExecutableProduct("mrouter", :mrouter),
    ExecutableProduct("pipedgen", :pipedgen),
    ExecutableProduct("pyragen", :pyragen),
    ExecutableProduct("vl", :vl),
    ExecutableProduct("zbuf", :zbuf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GSL_jll"; compat="~2.7.2"),
    Dependency("Zlib_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
