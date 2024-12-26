# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GnuPG"
version = v"2.4.7"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(version).tar.bz2",
                  "7b24706e4da7e0e3b06ca068231027401f238102c41c909631349dcc3b85eb46"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnupg-*
# Use Windows LDAP
FLAGS=(LDAPLIBS="-lwldap32")
if [[ "${target}" == *86*-linux-gnu ]]; then
    # We have an old glibc which doesn't have `IN_EXCL_UNLINK`
    FLAGS=+(ac_cv_func_inotify_init=no)
    # Add -lrt dependency to fix the error
    #     undefined reference to `clock_gettime'
    atomic_patch -p1 ../patches/intel-linux-gnu-add-rt-lib.patch
fi
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()
# Missing dependencies
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    # ExecutableProduct("dirmngr", :dirmngr),
    # ExecutableProduct("dirmngr-client", :dirmngr_client),
    ExecutableProduct("gpg", :gpg),
    ExecutableProduct("gpg-agent", :gpg_agent),
    ExecutableProduct("gpgconf", :gpgconf),
    ExecutableProduct("gpg-connect-agent", :gpg_connect_agent),
    ExecutableProduct("gpgscm", :gpgscm),
    ExecutableProduct("gpgsm", :gpgsm),
    # ExecutableProduct("gpgsplit", :gpgsplit),
    ExecutableProduct("gpgtar", :gpgtar),
    ExecutableProduct("gpgv", :gpgv),
    # ExecutableProduct("gpg-wks-server", :gpg_wks_server),
    ExecutableProduct("kbxutil", :kbxutil),
    # ExecutableProduct("watchgnupg", :watchgnupg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need this to run a host yat2m executable
    HostBuildDependency("Libgpg_error_jll"),
    # We need this to run a host msgfmt executable
    HostBuildDependency("Gettext_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.15"),
    Dependency("Libksba_jll"),
    Dependency("Libgcrypt_jll"),
    Dependency("Libgpg_error_jll"; compat="1.51.0"),
    Dependency("nPth_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libassuan_jll"),
    Dependency("OpenLDAPClient_jll"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("SQLite_jll"),
    Dependency("libusb_jll"),
    Dependency("Nettle_jll"; compat="~3.10.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
