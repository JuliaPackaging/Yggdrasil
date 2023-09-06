using BinaryBuilder

name = "OpenSSH"
version = v"9.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.4p1.tar.gz",
                  "3608fd9088db2163ceb3e600c85ab79d0de3d221e59192ea1923e23263866a85"),
    ArchiveSource("https://mirror.msys2.org/msys/x86_64/openssh-9.4p1-1-x86_64.pkg.tar.zst",
                  "c719753161881a616ca38bac39e6ddb0b6f251fd07f1d4de88dc8908e1bcd7bf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license openssh-*/LICENCE
PRODUCTS=(ssh${exeext} ssh-add${exeext} ssh-keygen${exeext} ssh-keyscan${exeext} ssh-agent${exeext} scp${exeext})

if [[ "${target}" == *-mingw* ]]; then

    cd usr/bin

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
        # have trouble running the programs at runtime.
        conf_args+=(ac_cv_lib_crypt_crypt=no)
    fi

    # OpenSSH's check (as of OpenSSH 9.4) of the zlib version number does not work for zlib >= 1.3
    conf_args+=(--without-zlib-version-check)

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

# We do not (yet?) know how to build for Windows, and we do not have i686 Windows binaries that use OpenSSL @3
filter!(p -> !(Sys.iswindows(p) && nbits(p) == 32), platforms)

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
    Dependency("OpenSSL_jll"; compat="3.0.8", platforms=filter(!Sys.iswindows, platforms)),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
