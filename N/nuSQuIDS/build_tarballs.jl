# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nuSQuIDS"
version = v"1.13.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jsalvado/SQuIDS.git",
              "cd0ccd164b2fe34a59908e8d8aa370464105b107"),  # v1.3.1
    GitSource("https://github.com/arguelles/nuSQuIDS.git",
              "104914da5a25cb0d1548d19dd9f3161c693ce153"),  # v1.13.3
]

# Bash recipe for building across all platforms
#
# Both SQuIDS and nuSQuIDS use custom (non-autoconf) configure scripts that have
# several cross-compilation issues in BinaryBuilder:
#   1. The scripts use `uname -s` to detect the target OS, but in BinaryBuilder the
#      host is always Linux regardless of target. This causes wrong shared library
#      suffixes (.so vs .dylib) and linker flags (-shared vs -dynamiclib).
#   2. Manual dependency checks require static libraries (.a files), but JLL packages
#      only provide shared libraries.
#   3. nuSQuIDS's HDF5 auto-detection requires `h5cc`, which is not available for
#      cross-compilation. The pkg-config fallback is commented out in the source.
#   4. The configure scripts require bash features not available in BinaryBuilder's
#      /bin/sh (busybox ash), so we invoke them with `bash` explicitly.
#
# The build script patches both configure scripts via sed to fix issues 1-3.
script = raw"""
cd $WORKSPACE/srcdir

# ============================================================
# Determine target OS for cross-compilation overrides
# The configure scripts use `uname -s` which returns the HOST
# OS (always Linux in BinaryBuilder), not the TARGET OS.
# ============================================================
if [[ "${target}" == *-apple-* ]]; then
    TARGET_OS="Darwin"
elif [[ "${target}" == *-freebsd* ]]; then
    TARGET_OS="FreeBSD"
else
    TARGET_OS="Linux"
fi

# ============================================================
# Create pkg-config .pc files for JLL dependencies
# Some JLL artifacts don't ship .pc files, which causes the
# configure scripts' pkg-config fallback to fail.
# ============================================================
mkdir -p ${libdir}/pkgconfig

# Only create .pc files if the JLL artifact doesn't provide them
if [ ! -f ${libdir}/pkgconfig/gsl.pc ]; then
cat > ${libdir}/pkgconfig/gsl.pc <<PKGEOF
prefix=${prefix}
libdir=${libdir}
includedir=${includedir}

Name: gsl
Description: GNU Scientific Library
Version: 2.7.0
Libs: -L\${libdir} -lgsl -lgslcblas -lm
Cflags: -I\${includedir}
PKGEOF
fi

if [ ! -f ${libdir}/pkgconfig/hdf5.pc ]; then
cat > ${libdir}/pkgconfig/hdf5.pc <<PKGEOF
prefix=${prefix}
libdir=${libdir}
includedir=${includedir}

Name: hdf5
Description: HDF5
Version: 1.14.0
Libs: -L\${libdir} -lhdf5
Cflags: -I\${includedir}
PKGEOF
fi

if [ ! -f ${libdir}/pkgconfig/hdf5_hl.pc ]; then
cat > ${libdir}/pkgconfig/hdf5_hl.pc <<PKGEOF
prefix=${prefix}
libdir=${libdir}
includedir=${includedir}

Name: hdf5_hl
Description: HDF5 High-Level
Version: 1.14.0
Requires: hdf5
Libs: -L\${libdir} -lhdf5_hl
Cflags: -I\${includedir}
PKGEOF
fi

# ============================================================
# Build SQuIDS (dependency of nuSQuIDS)
# ============================================================
cd $WORKSPACE/srcdir/SQuIDS
mkdir -p lib

# Patch: Override OS detection so DYN_SUFFIX and linker flags
# are set correctly for the TARGET, not the build host.
sed -i "s|OS_NAME=.*uname -s.*|OS_NAME=\"${TARGET_OS}\"|" configure

# Patch: Accept shared libraries instead of requiring static (.a)
sed -i "s|libgsl\.a|libgsl.${dlext}|g" configure

# Must use bash - BinaryBuilder's /bin/sh (busybox ash) cannot
# parse these custom configure scripts.
bash ./configure --prefix=${prefix} \
    --with-gsl-incdir=${includedir} \
    --with-gsl-libdir=${libdir}

make -j${nproc}
make install

# ============================================================
# Build nuSQuIDS
# ============================================================
cd $WORKSPACE/srcdir/nuSQuIDS
mkdir -p lib build

# Patch: Override OS detection in check_os_arch()
sed -i "s|OS_NAME=.*uname -s.*|OS_NAME=\"${TARGET_OS}\"|" configure

# Patch: Accept shared libraries instead of requiring static (.a)
# for all manually-specified dependency paths.
sed -i "s|libgsl\.a|libgsl.${dlext}|g" configure
# HDF5: This is the CRITICAL fix. Without it, the manual HDF5 check
# fails (no .a files), the h5cc fallback fails (not available for
# cross-compilation), and the pkg-config fallback is commented out.
sed -i "s|libhdf5\.a|libhdf5.${dlext}|g" configure
sed -i "s|libhdf5_hl\.a|libhdf5_hl.${dlext}|g" configure
# SQuIDS
sed -i "s|libSQuIDS\.a|libSQuIDS.${dlext}|g" configure

bash ./configure --prefix=${prefix} \
    --with-squids=${prefix} \
    --with-gsl-incdir=${includedir} \
    --with-gsl-libdir=${libdir} \
    --with-hdf5-incdir=${includedir} \
    --with-hdf5-libdir=${libdir}

# Patch Makefile: BinaryBuilder's busybox `head` doesn't support /dev/stdin.
# The Makefile uses `head -c N /dev/stdin` to truncate after sed, but we can
# just pipe directly without the explicit /dev/stdin argument.
sed -i 's|/dev/stdin >|>|g' Makefile

make -j${nproc}
make install

# Ensure data files are installed
mkdir -p ${prefix}/share/nuSQuIDS
cp -r data/* ${prefix}/share/nuSQuIDS/

# Install license
install_license LICENSE
"""

# Platforms - Linux (glibc) and macOS
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# Expand C++ string ABI (required for C++ libraries on Linux)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libSQuIDS", :libSQuIDS),
    LibraryProduct("libnuSQuIDS", :libnuSQuIDS),
    FileProduct("share/nuSQuIDS", :nuSQuIDS_data),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GSL_jll"; compat="~2.8"),
    Dependency("HDF5_jll"; compat="~1.14"),
    Dependency("LibCURL_jll"; compat="7.73,8"),  # Required by HDF5_jll for ROS3 VFD support
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
