# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "telnet"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/inetutils/inetutils-$(version.major).$(version.minor).tar.xz",
                  "d547f69172df73afef691a0f7886280fd781acea28def4ff4b4b212086a89d80")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/inetutils-*
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

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-ifconfig \
    --disable-hostname \
    --disable-logger \
    --disable-rcp \
    --disable-rexec \
    --disable-rlogin \
    --disable-rsh \
    --disable-tftp \
    --disable-traceroute \
    --disable-inetd \
    --disable-rexecd \
    --disable-syslogd \
    --disable-tftpd \
    "${conf_args[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    ExecutableProduct("telnet", :telnet)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95")) 
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
