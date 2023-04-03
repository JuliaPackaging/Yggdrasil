using BinaryBuilder

name = "OpenSSH"
version = v"9.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openssh/openssh-portable.git",
                  "6dfb65de949cdd0a5d198edee9a118f265924f33"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.0.0p1-Beta/OpenSSH-Win32.zip",
                  "d6a381b6b1c0d17433ca0b81cf65d139d55a0f8c249f07ec9e2cf02f3effeff0"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.0.0p1-Beta/OpenSSH-Win64.zip",
                  "d0c272360163ef2e99cab1c0941834605abf2e792377979ff21cbb09b55f3348"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license openssh-portable/LICENCE
PRODUCTS=(ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext})

if [[ "${target}" == *-mingw* ]]; then
    cd "${target}/OpenSSH-Win${nbits}"
else
    cd openssh-portable

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
    install -Dvm 0755 $binary ${bindir}/$binary
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
    Dependency("OpenSSL_jll"; compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
