using BinaryBuilder

name = "OpenSSH"
version = v"9.9.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.9p2.tar.gz",
                  "91aadb603e08cc285eddf965e1199d02585fa94d994d6cae5b41e1721e215673"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win32.zip",
                  "9245c9ff62d6d11708cb3125097f8cd5627e995c225d0469cf2c3c6be4014952"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip",
                  "bd48fe985d400402c278c485db20e6a82bc4c7f7d8e0ef5a81128f523096530c"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

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
