# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libssh"
version = v"0.11.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.libssh.org/files/$(version.major).$(version.minor)/libssh-$(version).tar.xz", "7d8a1361bb094ec3f511964e78a5a4dba689b5986e112afabe4f4d0d6c6125c3")
]

# Bash recipe for building across all platforms
script = raw"""
# Necessary for cmake to find openssl on Windows
if [[ ${target} == x86_64-*-mingw* ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64
fi

DOC_DIR=${prefix}/usr/share/doc/libssh

# Build and install library
cd $WORKSPACE/srcdir/libssh-*
mkdir build
cd build/

# Kerberos_krb5_jll is only built for Linux and FreeBSD, so GSSAPI support is
# only available on those platforms.
if [[ ${target} == *linux* || ${target} == *freebsd* ]]; then
    export GSSAPI_ENABLED=ON
else
    export GSSAPI_ENABLED=OFF
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
                                     -DCMAKE_BUILD_TYPE=Release \
                                     -DWITH_GSSAPI=${GSSAPI_ENABLED} \
                                     -DWITH_EXAMPLES=OFF ..

make -j${nproc}
make docs install

# Install Doxygen tagfile
mkdir -p ${DOC_DIR}
install -Dv ../doc/tags.xml "${DOC_DIR}/tags.xml"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libssh", :libssh),
    FileProduct("usr/share/doc/libssh/tags.xml", :doxygen_tags)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Doxygen_jll"),
    Dependency("Kerberos_krb5_jll"; compat="1.19.3"),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.16"),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"); compat="1.2.12")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
