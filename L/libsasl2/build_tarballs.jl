# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsasl2"
version = v"2.1.28"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-$(version)/cyrus-sasl-$(version).tar.gz",
                  "7ccfc6abd01ed67c1a0924b353e526f1b766b21f42d4562ee635a8ebfc5bb38c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cyrus-sasl*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_gssapi_supports_spnego=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)


# The products that we will ensure are always built
products = [
    LibraryProduct("libsasl2", :libsasl2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="1.1.10"),
    Dependency(PackageSpec(name="libxcrypt_legacy_jll", uuid="5ef642bb-a58b-5208-ae37-583168b2c491"); platforms=filter(p -> libc(p) == "glibc", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
