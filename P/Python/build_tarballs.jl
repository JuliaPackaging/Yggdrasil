# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Python"
version = v"3.12.14"

# Collection of sources required to build Python
sources = [
    ArchiveSource("https://www.python.org/ftp/python/$(version)/$(name)-$(version).tar.xz",
                  "5c8462af5790baf43a321a1559dbe0db06d1be4300fb85fb53c40060668e548a"),
    # Deliberately an installer from the same 24.3.0 generation as the py311 one
    # this replaced: Miniconda installers from 24.11 onwards gate on
    # `ldd --version` reporting GLIBC >= 2.28, which fails outright in
    # BinaryBuilder's musl sandbox ("Installer requires GLIBC >=2.28, but system
    # has ."). Do not casually bump this to the newest available.
    FileSource("https://repo.anaconda.com/miniconda/Miniconda3-py312_24.3.0-0-Linux-x86_64.sh",
                "96a44849ff17e960eeb8877ecd9055246381c4d4f2d031263b63fa7e2e930af1", "miniconda.sh"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# Python's autoconf scripts use non-default macros
apk add autoconf-archive

# Having a global `python3` screws things up a bit, so get rid of that
rm -f $(which python3)

# Install miniconda to get the build python necessary for cross-compilation
# (--with-build-python must be at least the version being built).
cd ${WORKSPACE}/srcdir
bash miniconda.sh -b -p ${host_bindir}/miniconda


# We need these for the host python build
apk update
apk add zlib-dev libffi-dev

# Create fake `arch` command:
echo '#!/bin/bash' >> /usr/bin/arch
if [[ "${target}" == *-apple-* ]]; then
    echo 'echo i386'  >> /usr/bin/arch
else
    echo 'echo `echo $target | cut -d - -f 1`'  >> /usr/bin/arch
fi
chmod +x /usr/bin/arch

# Patch out cross compile limitations
cd ${WORKSPACE}/srcdir/Python-*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross_compile_configure_ac.patch

# Disable detection of multiarch as it breaks with clang >= 13, which adds a
# major.minor version number in -print-multiarch output, confusing Python.
# https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=258377
if [[ "${target}" == *-freebsd* || ${target} == *darwin* ]]; then
    sed -i 's|^MULTIARCH=.*|MULTIARCH=|' configure.ac
fi

autoreconf -i

# Next, build host version
mkdir build_host && cd build_host

# Override `bb_target`, `CC`, etc... to give this `./configure` the impression
# that we are actually targeting `${MACHTYPE}` and not `${target}`
bb_target=${MACHTYPE} CC=${HOSTCC} CPPFLAGS=-I/usr/include LDFLAGS="-L/lib -L/usr/lib" ../configure --host="${MACHTYPE}" --build="${MACHTYPE}"
make -j${nproc} python sharedmods

# Next, build target version
cd ${WORKSPACE}/srcdir/Python-*/
mkdir build_target && cd build_target

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"
export PATH=$(echo ${WORKSPACE}/srcdir/Python-*/build_host):$PATH

conf_args=()
conf_args+=(--with-build-python=${host_bindir}/miniconda/bin/python)
conf_args+=(--enable-shared)
conf_args+=(--disable-ipv6)
conf_args+=(--with-ensurepip=no)
conf_args+=(--disable-test-modules)
conf_args+=(--with-system-expat)
conf_args+=(--with-system-ffi)
conf_args+=(--with-system-libmpdec)
conf_args+=(--enable-optimizations)
conf_args+=(ac_cv_file__dev_ptmx=no)
conf_args+=(ac_cv_file__dev_ptc=no)
conf_args+=(ac_cv_have_chflags=no)

../configure --prefix="${prefix}" --host="${target}" --build="${MACHTYPE}" "${conf_args[@]}"

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/Python-*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable windows for now, until we can sort through all of these patches
# and choose the ones that we need:
# https://github.com/msys2/MINGW-packages/tree/1e753359d9b55a46d9868c3e4a31ad674bf43596/mingw-w64-python3
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("python3", :python),
    LibraryProduct("libpython3", :libpython),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Libffi_jll"; compat="~3.4.6"),
    Dependency("SQLite_jll"),
    Dependency("LibMPDec_jll"; compat="2.5.1"),
    Dependency("Zlib_jll"),
    Dependency("XZ_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

init_block = raw"""
ENV["PYTHONHOME"] = artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
# Python 3.12 uses C11 thread-local storage (`_Thread_local` in
# pycore_pystate.h). BinaryBuilder's default GCC 4.8.5 defaults to gnu89 and
# fails with "unknown type name '_Thread_local'"; GCC >= 5 defaults to gnu11.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               init_block, julia_compat = "1.6", preferred_gcc_version = v"9")
