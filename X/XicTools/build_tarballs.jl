# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XicTools"
version = v"4.3.19"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wrcad/xictools", "c7a50a5fcd71966730e45a5358b8507227ae098c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xictools/
cp Makefile.sample Makefile
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/Makefile.patch
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/malloc-2.8.6.c.patch
update_configure_scripts
make config
make all
make prefix="${prefix}/usr" install
install_license ${WORKSPACE}/srcdir/xictools/license/LICENSE-2.0.txt
cd ${prefix}/usr/xictools
FILES="wrspice.current/bin/mmjco
wrspice.current/bin/multidec
wrspice.current/bin/printtoraw
wrspice.current/bin/proc2mod
wrspice.current/bin/wrspice
wrspice.current/bin/wrspiced
bin/admsXml
bin/busgen
bin/capgen
bin/cubegen
bin/fastcap
bin/fasthenry
bin/fcpp
bin/lstpack
bin/lstunpack
bin/mrouter
bin/pipedgen
bin/pyragen
bin/vl
xic.current/bin/wrencode
xic.current/bin/wrdecode
xic.current/bin/wrsetpass
xic.current/bin/xic
bin/zbuf"
for file in $FILES; do
    install -Dvm 755 "${file}" "${bindir}/$(basename ${file})"
    rm "${file}"
    ln -s "${bindir}/$(basename ${file})" "${file}"
done
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
	    ExecutableProduct("proc2mod", :proc2mod),
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
	    ExecutableProduct("wrdecode", :wrdecode),
	    ExecutableProduct("wrencode", :wrencode),
	    ExecutableProduct("xic", :xic),
	    ExecutableProduct("zbuf", :zbuf),
	    ]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("GSL_jll"; compat="~2.7.2"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
