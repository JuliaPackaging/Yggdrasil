# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LAL"
version = v"7.7.1"

# LALSuite tag: lal-v7.7.1
sources = [
    GitSource(
        "https://github.com/lscsoft/lalsuite.git",
        "fd81149d68cb3c9424fcfe229e697ee534ac02ab",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lalsuite/lal

./00boot
update_configure_scripts

# GitSource checkouts do not retain .git metadata.  LAL's release archives
# contain this generated header, so recreate the release-tagged form here.
sed \
    -e 's%@PACKAGE_NAME@%LAL%g' \
    -e 's%@PACKAGE_NAME_UCASE@%LAL%g' \
    -e 's%@PACKAGE_NAME_LCASE@%lal%g' \
    -e 's%@PACKAGE_NAME_NOLAL@%%g' \
    -e 's%@PACKAGE_VCS_INFO_HEADER@%lal/LALVCSInfo.h%g' \
    -e 's%@PACKAGE_CONFIG_HEADER@%lal/LALConfig.h%g' \
    -e 's%@ID@%fd81149d68cb3c9424fcfe229e697ee534ac02ab%g' \
    -e 's%@DATE@%2026-02-01 22:19:30 +0000%g' \
    -e 's%@BRANCH@%None%g' \
    -e 's%@TAG@%lal-v7.7.1%g' \
    -e 's%@AUTHOR@%Karl Wette <karl.wette@ligo.org>%g' \
    -e 's%@COMMITTER@%Karl Wette <karl.wette@ligo.org>%g' \
    -e 's%@CLEAN@%CLEAN%g' \
    -e 's%@STATUS@%CLEAN: All modifications committed%g' \
    lib/LALVCSInfoHeader.h.git > lib/LALVCSInfoHeader.h

mkdir build
cd build

export CPPFLAGS="${CPPFLAGS} -I${includedir}"
export LDFLAGS="${LDFLAGS} -L${libdir}"
export PKG_CONFIG_PATH="${libdir}/pkgconfig:${PKG_CONFIG_PATH}"
export GSL_LIBS="-L${libdir} -lgsl -lgslcblas -lm"
export HDF5_LIBS="-L${libdir} -lhdf5 -lhdf5_hl"

../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-shared \
    --disable-python \
    --disable-swig \
    --disable-swig-python \
    --disable-swig-octave \
    --disable-doxygen \
    --disable-help2man \
    --disable-gcc-flags \
    --enable-pthread-lock \
    --with-hdf5=yes

cp ../lib/LALVCSInfoHeader.h lib/LALVCSInfoHeader.h

make -j${nproc} V=1 -C include
make -j${nproc} V=1 -C lib
make -j${nproc} V=1 -C lib install
make install-pkgconfigDATA

rm -f ${prefix}/share/man/man7/LAL_DEBUG_LEVEL.7
rmdir ${prefix}/share/man/man7 2>/dev/null || true

install_license ../COPYING

test -f ${includedir}/lal/LALDatatypes.h
test -f ${includedir}/lal/LALDict.h
test -f ${includedir}/lal/XLALError.h
test -f ${libdir}/pkgconfig/lal.pc
test -f ${libdir}/pkgconfig/lalsupport.pc
"""

# LALSuite's upstream package explicitly excludes Windows.
platforms = filter(!Sys.iswindows, supported_platforms())

products = [
    LibraryProduct("liblal", :liblal),
    LibraryProduct("liblalsupport", :liblalsupport),
    FileProduct("include/lal", :lal_headers),
]

dependencies = [
    Dependency("FFTW_jll"; compat="3.3.11"),
    Dependency("GSL_jll"; compat="2.8.1"),
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"6",
)
