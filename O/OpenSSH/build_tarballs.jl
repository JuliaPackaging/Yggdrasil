using BinaryBuilder

name = "OpenSSH"
version = v"10.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.3p1.tar.gz",
                  "56682a36bb92dcf4b4f016fd8ec8e74059b79a8de25c15d670d731e7d18e45f4"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.0.0.0p2-Preview/OpenSSH-Win32.zip",
                  "c61d7fea20ddfe0fc50eb56210a66464557721120f7794ff9cc883b5ba526abd"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/10.0.0.0p2-Preview/OpenSSH-Win64.zip",
                  "23f50f3458c4c5d0b12217c6a5ddfde0137210a30fa870e98b29827f7b43aba5"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir

install_license openssh-*/LICENCE
PRODUCTS=(ssh ssh-add ssh-keygen ssh-keyscan ssh-agent scp sftp)

if [[ "${target}" == *-mingw* ]]; then
    cd "${target}/OpenSSH-Win${nbits}"
else
    cd openssh-*

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

for binary in "${PRODUCTS[@]}"; do
    install -Dvm 0755 "${binary}${exeext}" -t "${bindir}"
done
if [[ "${target}" == *-mingw* ]]; then
    # Install also a library needed by the Windows executables.  We do provide
    # it in OpenSSL_jll, but with a different soname (`libcrypto-3-x64.dll`) and
    # so it can't be found.
    install -Dvm 0755 libcrypto.dll -t "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ssh", :ssh),
    ExecutableProduct("scp", :scp),
    ExecutableProduct("sftp", :sftp),
    ExecutableProduct("ssh-agent", :ssh_agent),
    ExecutableProduct("ssh-add", :ssh_add),
    ExecutableProduct("ssh-keygen", :ssh_keygen),
    ExecutableProduct("ssh-keyscan", :ssh_keyscan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"; platforms=filter(!Sys.iswindows, platforms)),
    Dependency("OpenSSL_jll"; compat="3.0.16", platforms=filter(!Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
