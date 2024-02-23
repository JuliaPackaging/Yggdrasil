# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XicTools"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wrcad/xictools", "c7a50a5fcd71966730e45a5358b8507227ae098c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xictools/
cp Makefile.sample Makefile
sed -i "s|enable-itopok=no|enable-itopok=yes|g" Makefile
sed -i "s|GFXLOC = --enable-gtk2=yes|#GFXLOC = --enable-gtk2=yes|g" Makefile
#sed -i "s|^SUBDIRS =.*|SUBDIRS = xt_base adms KLU vl wrspice|g" Makefile
sed -i "766c\#include <malloc.h>" xt_base/malloc/malloc-2.8.6.c
update_configure_scripts
make config
make all -j${nproc}
make prefix="${prefix}/usr" install
install_license ${WORKSPACE}/srcdir/xictools/license/LICENSE-2.0.txt
cd ${prefix}/usr/xictools
install -Dvm 755 wrspice.current/bin/mmjco "${bindir}/mmjco"
rm wrspice.current/bin/mmjco
install -Dvm 755 wrspice.current/bin/multidec "${bindir}/multidec"
rm wrspice.current/bin/multidec
install -Dvm 755 wrspice.current/bin/printtoraw "${bindir}/printtoraw"
rm wrspice.current/bin/printtoraw
install -Dvm 755 wrspice.current/bin/proc2mod "${bindir}/proc2mod"
rm wrspice.current/bin/proc2mod
install -Dvm 755 wrspice.current/bin/wrspice "${bindir}/wrspice"
rm wrspice.current/bin/wrspice
install -Dvm 755 wrspice.current/bin/wrspiced "${bindir}/wrspiced"
rm wrspice.current/bin/wrspiced
install -Dvm 755 bin/admsXml "${bindir}/admsXml"
rm bin/admsXml
install -Dvm 755 bin/busgen "${bindir}/busgen"
rm bin/busgen
install -Dvm 755 bin/capgen "${bindir}/capgen"
rm bin/capgen
install -Dvm 755 bin/cubegen "${bindir}/cubegen"
rm bin/cubegen
install -Dvm 755 bin/fastcap "${bindir}/fastcap"
rm bin/fastcap
install -Dvm 755 bin/fasthenry "${bindir}/fasthenry"
rm bin/fasthenry
install -Dvm 755 bin/fcpp "${bindir}/fcpp"
rm bin/fcpp
install -Dvm 755 bin/lstpack "${bindir}/lstpack"
rm bin/lstpack
install -Dvm 755 bin/lstunpack "${bindir}/lstunpack"
rm bin/lstunpack
install -Dvm 755 bin/mrouter "${bindir}/mrouter"
rm bin/mrouter
install -Dvm 755 bin/pipedgen "${bindir}/pipedgen"
rm bin/pipedgen
install -Dvm 755 bin/pyragen "${bindir}/pyragen"
rm bin/pyragen
install -Dvm 755 bin/vl "${bindir}/vl"
rm bin/vl
install -Dvm 755 xic.current/bin/wrdecode "${bindir}/wrdecode"
rm xic.current/bin/wrdecode
install -Dvm 755 xic.current/bin/wrencode "${bindir}/wrencode"
rm xic.current/bin/wrencode
install -Dvm 755 xic.current/bin/wrsetpass "${bindir}/wrsetpass"
rm xic.current/bin/wrsetpass
install -Dvm 755 xic.current/bin/xic "${bindir}/xic"
rm xic.current/bin/xic
install -Dvm 755 bin/zbuf "${bindir}/zbuf"
rm bin/zbuf
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
