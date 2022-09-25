# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rsync"
version = v"3.2.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.samba.org/pub/rsync/src/rsync-$(version).tar.gz", "fb3365bab27837d41feaf42e967c57bd3a47bc8f10765a3671efd6a3835454d3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd rsync-*/
install_license COPYING

CONFIGURE_FLAGS=(--prefix=${prefix} --build=${MACHTYPE} --host=${target})
# prefer to use JLLs instead of included deps
CONFIGURE_FLAGS+=(--with-included-popt=no)
CONFIGURE_FLAGS+=(--with-included-zlib=no)
# disable iconv (compilation failure on MacOS, and no --with-iconv to point to iconv_jll)
CONFIGURE_FLAGS+=(--disable-iconv)
CONFIGURE_FLAGS+=(--disable-iconv-open)
# don't include debug symbols
CONFIGURE_FLAGS+=(--disable-debug)

./configure ${CONFIGURE_FLAGS[@]}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> libc(p) != "musl", platforms)  # missing dependencies
filter!(!Sys.isfreebsd, platforms)          # missing dependencies
filter!(!Sys.iswindows, platforms)          # compilation failure

# The products that we will ensure are always built
products = [
    ExecutableProduct("rsync", :rsync)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Popt_jll", uuid="e80236cf-ab1d-5f5d-8534-1d1285fe49e8")),
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9")),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
