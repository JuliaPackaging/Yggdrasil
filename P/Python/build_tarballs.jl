# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Python"
version = v"3.10.14"

# Collection of sources required to build Python
sources = [
    ArchiveSource("https://www.python.org/ftp/python/$(version)/$(name)-$(version).tar.xz",
                  "9c50481faa8c2832329ba0fc8868d0a606a680fc4f60ec48d26ce8e076751fda"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# Python's autoconf scripts use non-default macros
apk add autoconf-archive

# Having a global `python3` screws things up a bit, so get rid of that
rm -f $(which python3)

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

# Don't link against libcrypt, because we provide libcrypt.so.1 while most systems will
# have libcrypt.so.2 (backported from Python 3.11)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libcrypt.patch

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
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
    Dependency("SQLite_jll"),
    Dependency("LibMPDec_jll"),
    Dependency("Zlib_jll"),
    Dependency("XZ_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.12"),
]

init_block = raw"""
ENV["PYTHONHOME"] = artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               init_block, julia_compat = "1.6")
