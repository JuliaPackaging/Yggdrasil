# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GnuPG"
version = v"2.2.27"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(version).tar.bz2",
                  "34e60009014ea16402069136e0a5f63d9b65f90096244975db5cea74b3d02399"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnupg-*/
if [[ "${target}" != ${MACHTYPE} ]]; then
    # Delete `gpg-error-config` of the host to prevent it from being picked up
    # when configuring the package
    rm "${host_bindir}/gpg-error-config"
fi
if [[ "${target}" == *86*-linux-gnu ]]; then
    # We have an old glibc which doesn't have `IN_EXCL_UNLINK`
    FLAGS=(ac_cv_func_inotify_init=no)
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

# The products that we will ensure are always built
products = [
    ExecutableProduct("dirmngr", :dirmngr),
    ExecutableProduct("dirmngr-client", :dirmngr_client),
    ExecutableProduct("gpg", :gpg),
    ExecutableProduct("gpg-agent", :gpg_agent),
    ExecutableProduct("gpgconf", :gpgconf),
    ExecutableProduct("gpg-connect-agent", :gpg_connect_agent),
    ExecutableProduct("gpgparsemail", :gpgparsemail),
    ExecutableProduct("gpgscm", :gpgscm),
    ExecutableProduct("gpgsm", :gpgsm),
    ExecutableProduct("gpgsplit", :gpgsplit),
    ExecutableProduct("gpgtar", :gpgtar),
    ExecutableProduct("gpgv", :gpgv),
    ExecutableProduct("gpg-wks-server", :gpg_wks_server),
    ExecutableProduct("kbxutil", :kbxutil),
    ExecutableProduct("watchgnupg", :watchgnupg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need this to run a host yat2m executable
    HostBuildDependency("Libgpg_error_jll"),
    Dependency("GnuTLS_jll"),
    Dependency("Libksba_jll"),
    Dependency("Libgcrypt_jll"),
    Dependency("Libgpg_error_jll"),
    Dependency("nPth_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libassuan_jll"),
    Dependency("OpenLDAPClient_jll"),
    Dependency("Bzip2_jll"),
    Dependency("SQLite_jll"),
    Dependency("libusb_jll"),
    Dependency("Nettle_jll", v"3.4.1", compat="~3.4.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
