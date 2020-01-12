# We need to disable ccache in this build, because ccache doesn't support
# Fortran 90 and modules would not be built otherwise.
ENV["BINARYBUILDER_USE_CCACHE"] = "false"

using BinaryBuilder

name = "QD"
version = v"2.3.22"

# Collection of sources required to build SDPA-QD
sources = [
    "https://www.davidhbailey.com/dhbsoftware/qd-2.3.22.tar.gz" =>
    "30c1ffe46b95a0e9fa91085949ee5fca85f97ff7b41cd5fe79f79bab730206d3",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qd-2.3.22
update_configure_scripts
./configure --enable-shared --enable-fast-install=no --prefix=$prefix --host=$target --build=${MACHTYPE}
make -j${nproc} module_ext=mod
make install module_ext=mod

install_license $WORKSPACE/srcdir/LBNL-BSD-License.docx
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libqd_f_main", :libqd_f_main),
    LibraryProduct("libqdmod", :libqdmod),
    LibraryProduct("libqd", :libqd)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
