# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.36.1"

# Collection of sources required to build Git
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz",
                  "405d4a0ff6e818d1f12b3e92e1ac060f612adcb454f6299f70583058cb508370"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2",
                  "7b7cce2d1a29bb18b661720c692b39a27b406cd4916d75cc62d5fe1bfd9a57ea"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2",
                  "38f4888db497ebe11f67c42a88ac1708fb5c68d53a398b4030b51a6116cce0e5"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/git-*/COPYING

if [[ "${target}" == *-ming* ]]; then
    # Fast path for Windows: just copy the content of the tarball to the prefix
    cp -r ${WORKSPACE}/srcdir/${target}/mingw${nbits}/* ${prefix}
    exit
fi

cd $WORKSPACE/srcdir/git-*/

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

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-curl \
    --with-expat \
    --with-openssl \
    --with-iconv=${prefix} \
    --with-libpcre2 \
    --with-zlib=${prefix} \
    "${CACHE_VALUES[@]}"
make -j${nproc}
make install INSTALL_SYMLINKS="yes, please"

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
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("Libiconv_jll"),
    Dependency("PCRE2_jll"; compat="10.35.0"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
