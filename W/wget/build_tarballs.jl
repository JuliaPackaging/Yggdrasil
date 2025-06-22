# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wget"
version = v"1.25.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/wget/wget-$(version).tar.gz",
                  "766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wget-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-ssl=openssl --with-openssl
make -j${nproc}
make install
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable windows because OpenSSL_jll is not available there
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("wget", :wget)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700"); compat="2.40.2"),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.15"),
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="libidn2_jll", uuid="e3d30ef0-22f3-5ccc-b703-2e063d8d1f30"); compat="2.3.7"),
    Dependency(PackageSpec(name="libpsl_jll", uuid="c4fadf96-db99-5883-8c55-41cf0165eeb0"); compat="0.21.5"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
