using BinaryBuilder

name = "OpenSSH"
version = v"8.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openssh/openssh-portable.git", "cdf1d0a9f5d18535e0a18ff34860e81a6d83aa5c"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win32.zip",
                  "88aaf9eafc64a11d2ba0894a1c24608f1b6d69408b19bb7b15287338fea76dd0"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip",
                  "c99240af89452610f66b7ce54c4fa3180b66aae2bc326afc2aac8fc1dd48f488"; unpack_target = "x86_64-w64-mingw32"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license openssh-portable/LICENCE
PRODUCTS=(ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext})

if [[ "${target}" == *-mingw* ]]; then
    cd "${target}/OpenSSH-Win${nbits}"
else
    cd openssh-portable/

    # Remove OpenSSL from the sysroot to avoid confusion
    rm -f /opt/${target}/${target}/sys-root/usr/lib/libcrypto.*
    rm -f /opt/${target}/${target}/sys-root/usr/lib/libssl.*
    rm -f /lib/libcrypto.so*
    rm -f /usr/lib/libcrypto.so*

    atomic_patch -p1 ../patches/makefile-rm-duplicate-object.patch

    export CPPFLAGS="-I${includedir}"
    autoreconf -vi
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
    make -j${nproc} "${PRODUCTS[@]}"
fi

mkdir -p ${bindir}
for binary in "${PRODUCTS[@]}"; do
    install -c -m 0755 $binary ${bindir}/$binary;
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ssh", :ssh),
    ExecutableProduct("scp", :scp),
    ExecutableProduct("ssh-agent", :ssh_agent),
    ExecutableProduct("ssh-add", :ssh_add),
    ExecutableProduct("ssh-keygen", :ssh_keygen),
    ExecutableProduct("ssh-keyscan", :ssh_keyscan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
    Dependency("OpenSSL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
