# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CyrusSASL"
version = v"2.1.27"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz", "26866b1549b00ffd020f188a43c258017fa1c382b3ddadd8201536f72efb05d5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cyrus-sasl-2.1.27/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-openssl=${prefix} --enable-ntlm --disable-gssapi --with-dblib=none
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libanonymous", :libanonymous, "lib/sasl2"),
    LibraryProduct("libplain", :libplan, "lib/sasl2"),
    LibraryProduct("libscram", :libscram, "lib/sasl2"),
    LibraryProduct("libotp", :libotp, "lib/sasl2"),
    LibraryProduct("libdigestmd5", :libdigestmd5, "lib/sasl2"),
    LibraryProduct("libcrammd5", :libcrammd5, "lib/sasl2"),
    LibraryProduct("libntlm", :libntlm, "lib/sasl2"),
    LibraryProduct("libsasl2", :libsasl2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
