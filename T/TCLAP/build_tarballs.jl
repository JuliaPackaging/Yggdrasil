using BinaryBuilder

name    = "TCLAP"
version = v"1.2.2"

sources = [
    ArchiveSource("https://sourceforge.net/projects/tclap/files/tclap-$(version).tar.gz",
                  "f5013be7fcaafc69ba0ce2d1710f693f61e9c336b6292ae4f57554f59fde5837"),
]

script = raw"""
cd tclap*
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
install_license COPYING
"""

platforms = [AnyPlatform()] # header-only

products = [
    # Export ONE representative header so downstreams can discover include/
    FileProduct("include/tclap/CmdLine.h", :tclap_cmdline_h),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
