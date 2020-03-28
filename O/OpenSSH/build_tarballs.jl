# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSSH"
version = v"8.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/PowerShell/openssh-portable/archive/v8.1.0.0.tar.gz", "500276ab704c2a2a2b493b6fbb8b820bf954a54a77785eb81d34e03e1c086fac")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openssh-portable-8.1.0.0
export CPPFLAGS="-I${prefix}/include"
autoreconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext}
mkdir -p ${bindir}
for binary in ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext}; do install -c -m 0755 -s $binary ${bindir}/$binary; done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("ssh-agent", :ssh_agent),
    LibraryProduct("ssh", :ssh),
    LibraryProduct("ssh-add", :ssh_add),
    LibraryProduct("ssh-keygen", :ssh_keygen),
    LibraryProduct("ssh-keyscan", :ssh_keyscan),
    LibraryProduct("scp", :scp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
