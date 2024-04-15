# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Aria2"
version = v"1.37.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/aria2/aria2/releases/download/release-$(version)/aria2-$(version).tar.xz",
                  "60a420ad7085eb616cb6e2bdf0a7206d68ff3d37fb5a956dc44242eb2f79b66b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aria2-*/

# Note: we explicitly set `LIBSSH2_LIBS` to avoid pulling in mbedtls when
# linking to older builds of libssh2.
./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic --enable-shared --enable-libaria2 \
    --with-openssl --with-libxml2 --with-libz --with-libssh2 \
    LIBSSH2_LIBS="-L${libdir} -lssh2 "

make -j${nproc}
make install

install_license COPYING
install_license LICENSE.OpenSSL
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("aria2c", :aria2c),
    LibraryProduct("libaria2", :libaria2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Cares_jll")),
    Dependency(PackageSpec(name="LibSSH2_jll")),
    Dependency(PackageSpec(name="OpenSSL_jll"); compat="3.0.8"),
    Dependency(PackageSpec(name="XML2_jll")),
    Dependency(PackageSpec(name="Zlib_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Option `-r' for `lld` is not yet implemented
               julia_compat="1.8", preferred_gcc_version=v"7", clang_use_lld=false)
