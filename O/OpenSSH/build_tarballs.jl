using BinaryBuilder

name = "OpenSSH"
version = v"9.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openssh/openssh-portable/archive/refs/tags/V_9_1_P1.tar.gz",
                  "8ae811262318653bbad319710b5055af5ac911d28f71ade5fb5ef604ac26821e"),
    # OpenSSH 9.1 is not yet (as of 2022-11-02) available for download there, so use 8.9.1.0 instead
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.9.1.0p1-Beta/OpenSSH-Win32.zip",
                  "b99c384811f9ef8cab7589460d607fd4d4faccd6ec08a7405a2df0a37340fdeb"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.9.1.0p1-Beta/OpenSSH-Win64.zip",
                  "b3d31939acb93c34236f420a6f1396e7cf2eead7069ef67742857a5a0befb9fc"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license openssh-portable-*/LICENCE
PRODUCTS=(ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext})

if [[ "${target}" == *-mingw* ]]; then
    cd "${target}/OpenSSH-Win${nbits}"
else
    cd openssh-portable-*

    # Remove OpenSSL from the sysroot to avoid confusion
    rm -f /opt/${target}/${target}/sys-root/usr/lib/libcrypto.*
    rm -f /opt/${target}/${target}/sys-root/usr/lib/libssl.*
    rm -f /lib/libcrypto.so*
    rm -f /usr/lib/libcrypto.so*

    conf_args=()
    if [[ "${target}" == *-linux-gnu* ]]; then
        # We use very old versions of glibc which used to have `libcrypt.so.1`, but modern
        # glibcs have `libcrypt.so.2`, so if we link to `libcrypt.so.1` most users would
        # have troubles running the programs at runtime.
        conf_args+=(ac_cv_lib_crypt_crypt=no)
    fi

    export CPPFLAGS="-I${includedir}"
    autoreconf -vi
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${conf_args[@]}"
    make -j${nproc} "${PRODUCTS[@]}"
fi

mkdir -p ${bindir}
for binary in "${PRODUCTS[@]}"; do
    install -c -m 0755 $binary ${bindir}/$binary
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
    Dependency("OpenSSL_jll"; compat="1.1.20")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
