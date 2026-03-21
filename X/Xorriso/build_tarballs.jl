# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xorriso"
version = v"1.5.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.gnu.org/software/xorriso/xorriso-1.5.6.pl02.tar.gz", "786f9f5df9865cc5b0c1fecee3d2c0f5e04cab8c9a859bd1c9c7ccd4964fdae1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xorriso-*

# MacOS specific configuration
if [[ "${target}" == *-apple-* ]]; then
    export LDFLAGS="-L${libdir}"
    export LIBS="-liconv"
    export CPPFLAGS="-I${includedir}"
fi

update_configure_scripts # to add riscv support

./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} --disable-launch-frontend
make -j${nproc}

install_license COPYING
install -Dvm 755 "xorriso/xorriso${exeext}" "${bindir}/xorriso${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("xorriso", :xorriso)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Readline_jll"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Libiconv_jll"),
    Dependency("acl_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Attr_jll", platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
