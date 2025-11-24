# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "rsync"
version = v"3.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.samba.org/pub/rsync/src/rsync-$(version).tar.gz",
                  "2924bcb3a1ed8b551fc101f740b9f0fe0a202b115027647cf69850d65fd88c52"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rsync-*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/strlcpy.patch

CONFIGURE_FLAGS=(--prefix=${prefix} --build=${MACHTYPE} --host=${target})
# prefer to use JLLs instead of included deps
CONFIGURE_FLAGS+=(--with-included-popt=no)
CONFIGURE_FLAGS+=(--with-included-zlib=no)
# disable iconv (compilation failure on MacOS, and no --with-iconv to point to iconv_jll)
CONFIGURE_FLAGS+=(--disable-iconv)
CONFIGURE_FLAGS+=(--disable-iconv-open)
# don't include debug symbols
CONFIGURE_FLAGS+=(--disable-debug)

# The default settings for `includedir`, `libdir`, and `bindir`
# contain an unexpanded `${prefix}`. This is not expanded in our `cc`
# wrapper. This means that dependencies are not found. (This may
# happen only on some architectures?)
./configure ${CONFIGURE_FLAGS[@]} includedir=${includedir} libdir=${libdir} bindir=${bindir}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# We don't know how to link against OpenSSL (this should be fixable)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rsync", :rsync)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147")),
    # Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.13"),
    # Until we have a new version of OpenSSL built for riscv64 we need to use the
    # `get_addable_spec` hack.  From v3.0.16 we should be able to remove it here.
    Dependency(get_addable_spec("OpenSSL_jll", v"3.0.15+2"); compat="3.0.15"),
    Dependency(PackageSpec(name="Popt_jll", uuid="e80236cf-ab1d-5f5d-8534-1d1285fe49e8")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
