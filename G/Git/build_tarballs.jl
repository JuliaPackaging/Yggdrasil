# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
upstream_version = v"2.53.0"
version = upstream_version

# <https://github.com/git-for-windows/git/releases> says:
# "Git for Windows v2.48.1 was the last version to ship with the i686 ("32-bit") variant of the installer, portable Git and archive."
# But v2.50.1 was made available "after warranty" to address critical vulnerabilities: https://github.com/git-for-windows/git/releases/tag/v2.50.1.windows.1
last_windows_32_bit_version = v"2.50.1"

# Collection of sources required to build Git
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(upstream_version).tar.xz",
                  "5818bd7d80b061bbbdfec8a433d609dc8818a05991f731ffc4a561e2ca18c653"),
    # Use FileSources instead of ArchiveSources because unpacking archives takes a long time and is not necessary on most platforms
    FileSource("https://github.com/git-for-windows/git/releases/download/v$(last_windows_32_bit_version).windows.1/Git-$(last_windows_32_bit_version)-32-bit.tar.bz2",
               "796d8f4fdd19c668e348d04390a3528df61cfc9864d1f276d9dc585a8a0ac82c"),
    FileSource("https://github.com/git-for-windows/git/releases/download/v$(upstream_version).windows.1/Git-$(upstream_version)-64-bit.tar.bz2",
               "d0a44fba2cc47e053ed987584d8392675c12a1465690ad1a36f09743a2ffe15e"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/git-*/COPYING

if [[ ${target} == *-mingw* ]]; then
    # Fast path for Windows: just unpack the tarballs in the prefix
    cd ${prefix}
    tar xjf ${WORKSPACE}/srcdir/Git-*-${nbits}-bit.tar.bz2
    # Delete symbolic links, which can't be created on Windows
    echo "Deleting symbolic links..."
    find . -type l -print -delete
    mv * ${prefix}
    exit
fi

cd $WORKSPACE/srcdir/git-*

# We need a native "tclsh" to cross-compile
apk update
apk add tcl

CACHE_VALUES=()
if [[ "${target}" != *86*-linux-* ]]; then
    # Cache values of some tests, let's hope to have got them right
    CACHE_VALUES+=(
        ac_cv_iconv_omits_bom=no
        ac_cv_fread_reads_directories=yes
        ac_cv_snprintf_returns_bogus=no
    )
else
    # Explain Git that we aren't cross-compiling on these platforms
    sed -i 's/cross_compiling=yes/cross_compiling=no/' configure
fi

# On Linux, we need at least glibc 2.25 or musl 1.1.20 to get `sys/random.h`.
# Git does not check whether this file exists. Explicitly disable `getrandom` if this file doesn't exist.
MAKE_VARIABLES=()
if [[ "${target}" == *-linux-* ]]; then
    if [ ! -e /opt/${target}/${target}/sys-root/usr/include/sys/random.h ]; then
        MAKE_VARIABLES+=(CSPRNG_METHOD=/dev/urandom)
    fi
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-curl \
    --with-expat \
    --with-openssl \
    --with-iconv=${prefix} \
    --with-libpcre2 \
    --with-zlib=${prefix} \
    --with-tcltk=no \
    "${CACHE_VALUES[@]}"
make -j${nproc} "${MAKE_VARIABLES[@]}"
make install INSTALL_SYMLINKS="yes, please" "${MAKE_VARIABLES[@]}"

# Because of the System Integrity Protection (SIP), when running shell or Perl scripts, the
# environment variable `DYLD_FALLBACK_LIBRARY_PATH` is reset.  We work around this
# limitation by re-exporting `DYLD_FALLBACK_LIBRARY_PATH` through another environment
# variable called `JLL_DYLD_FALLBACK_LIBRARY_PATH` which won't be reset by SIP.
# Read more about the issue and the hacks we apply here at
# <https://github.com/JuliaVersionControl/Git.jl/issues/40>.
if [[ "${target}" == *-apple-* ]]; then
    # Rename the `git` binary executable
    mv "${bindir}/git" "${bindir}/_git"

    # Create a shell driver called `git` which re-exports `DYLD_FALLBACK_LIBRARY_PATH` for us
    cat > "${bindir}/git" << 'EOF'
#!/bin/bash

# We need to canonicalize symlinks, but older versions of `readlink` on macOS don't have the
# `-f` option, so we need to cook up our own.  Adapted from
# <https://stackoverflow.com/a/1116890/2442087>.
readlink_f() {
    TARGET_FILE="${1}"

    cd "$(dirname "${TARGET_FILE}")"
    TARGET_FILE="$(basename ${TARGET_FILE})"

    # Iterate down a (possible) chain of symlinks
    while [ -L "${TARGET_FILE}" ]; do
        TARGET_FILE="$(readlink "${TARGET_FILE}")"
        cd "$(dirname "${TARGET_FILE}")"
        TARGET_FILE="$(basename "${TARGET_FILE}")"
    done

    # Compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    PHYS_DIR="$(pwd -P)"
    echo "${PHYS_DIR}/${TARGET_FILE}"
}

SCRIPT_DIR=$( cd -- "$( dirname -- $(readlink_f "${BASH_SOURCE[0]}") )" &> /dev/null && pwd )
export DYLD_FALLBACK_LIBRARY_PATH="${JLL_DYLD_FALLBACK_LIBRARY_PATH}"
exec -a "${BASH_SOURCE[0]}" "${SCRIPT_DIR}/_git" "$@"
EOF

    # Make the script executable
    chmod +x "${bindir}/git"
fi
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("git", :git),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Libiconv_jll"),
    Dependency("PCRE2_jll"; compat="10.42.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
