using BinaryBuilder

name = "TulipIndicators"
version = v"0.9.1"
hash = "85147c3db868dca9880f78b26de9f4fcecf95fb9" # last rev as of 2022-07-14

sources = [
	GitSource("https://github.com/TulipCharts/tulipindicators.git", hash)
]

deps = [
	HostBuildDependency("Tcl_jll")
]

script = raw"""
if ! command -v tclsh &> /dev/null
then
	cd ${host_bindir}
	ln -s tclsh* tclsh
fi
cd $WORKSPACE/srcdir/tulipindicators
make tiamalgamation.c
mkdir -p ${includedir} ${libdir}
cc -fPIC -shared -Wall -Wextra -Wshadow -Wconversion -std=c99 -pedantic -O2 -g tiamalgamation.c -o ${libdir}/libindicators.${dlext}
cp candles.h indicators.h ${includedir}
"""

platforms = supported_platforms()

products = [
	LibraryProduct("libindicators", :libindicators),
	FileProduct("include/candles.h", :candles_h),
	FileProduct("include/indicators.h", :indicators_h)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, deps; julia_compat="1.6")
