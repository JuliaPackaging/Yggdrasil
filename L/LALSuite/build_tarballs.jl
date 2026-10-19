using BinaryBuilder, Pkg

name = "LALSuite"
version = v"7.26.16"

# Protected upstream tag; commit 548bc5710bea021239da56e9beff1feaae163956.
sources = [
    ArchiveSource(
        "https://git.ligo.org/lscsoft/lalsuite/-/archive/lalsuite-v$(version)/lalsuite-lalsuite-v$(version).tar.gz",
        "ca263715e3378577b90103ce4c7de78acccac4afecb87ba44b85807e497964b1",
    ),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lalsuite-*

# Python embedding is probed independently of --disable-python in this release.
atomic_patch -p1 ../patches/binary-provider.patch

export CPPFLAGS="${CPPFLAGS} -I${includedir}"
export LDFLAGS="${LDFLAGS} -L${libdir}"
export PKG_CONFIG_PATH="${libdir}/pkgconfig:${PKG_CONFIG_PATH}"
export GSL_LIBS="-L${libdir} -lgsl -lgslcblas -lm"
export HDF5_LIBS="-L${libdir} -lhdf5_hl -lhdf5"
export SOURCE_DATE_EPOCH=1790889543

# Build only these two components, in dependency order. Avoid installing programs,
# Python modules, test executables, and documentation from their top-level targets.
for package in LAL LALSimulation; do
    component=$(echo ${package} | tr '[:upper:]' '[:lower:]')
    pushd ${component}
    autoreconf -fiv
    update_configure_scripts

    # GitLab source archives omit generated VCS headers. Reproduce the release
    # metadata without creating a synthetic git history or consulting the host.
    uppercase=$(echo ${package} | tr '[:lower:]' '[:upper:]')
    sed \
        -e "s%@PACKAGE_NAME@%${package}%g" \
        -e "s%@PACKAGE_NAME_UCASE@%${uppercase}%g" \
        -e "s%@PACKAGE_NAME_LCASE@%${component}%g" \
        -e "s%@PACKAGE_NAME_NOLAL@%${package#LAL}%g" \
        -e "s%@PACKAGE_VCS_INFO_HEADER@%lal/${package}VCSInfo.h%g" \
        -e "s%@PACKAGE_CONFIG_HEADER@%lal/${package}Config.h%g" \
        -e 's%@ID@%548bc5710bea021239da56e9beff1feaae163956%g' \
        -e 's%@DATE@%2026-10-01 21:19:03 +0000%g' \
        -e 's%@BRANCH@%None%g' \
        -e 's%@TAG@%lalsuite-v7.26.16%g' \
        -e 's%@AUTHOR@%Karl Wette <karl.wette@ligo.org>%g' \
        -e 's%@COMMITTER@%Karl Wette <karl.wette@ligo.org>%g' \
        -e 's%@CLEAN@%UNCLEAN%g' \
        -e 's%@STATUS@%UNCLEAN: release archive; Python embedding disabled by recipe%g' \
        lib/${package}VCSInfoHeader.h.git > lib/${package}VCSInfoHeader.h

    mkdir -v build
    pushd build
    ../configure \
        --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
        --enable-shared --disable-static \
        --disable-python --disable-swig --disable-swig-python --disable-swig-octave \
        --disable-doxygen --disable-help2man --disable-gcc-flags \
        --disable-openmp --disable-fast-gsl --enable-pthread-lock \
        --with-fallback-data-path=no --with-hdf5=yes
    cp -v ../lib/${package}VCSInfoHeader.h lib/${package}VCSInfoHeader.h
    make -j${nproc} -C include
    make -j${nproc} -C lib
    make -C lib install
    make install-pkgconfigDATA
    popd
    cp -v COPYING COPYING.${package}
    install_license COPYING.${package}
    popd
done

# pkg-config files must describe the relocated prefix, not BinaryBuilder's paths.
for pc in ${libdir}/pkgconfig/lal.pc ${libdir}/pkgconfig/lalsupport.pc ${libdir}/pkgconfig/lalsimulation.pc; do
    sed -i \
        -e 's|^prefix=.*|prefix=${pcfiledir}/../..|' \
        -e "s|-L${libdir} ||g" \
        -e "s|-I${includedir} ||g" "${pc}"
    ! grep -F "${WORKSPACE}" "${pc}"
done
test -f ${includedir}/lal/LALDatatypes.h
test -f ${includedir}/lal/LALSimInspiral.h
test -f lalsimulation/build/lib/config.h
! grep -q '^#define HAVE_PYTHON3_EMBED 1' lalsimulation/build/lib/config.h
"""

platforms = supported_platforms()
# Initial release coverage is limited to Linux glibc and macOS.
filter!(p -> Sys.isapple(p) || (Sys.islinux(p) && libc(p) == "glibc"), platforms)
# These are the four native release-validation targets requested by the consumer.
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)

products = [
    LibraryProduct("liblal", :liblal; dont_dlopen = true),
    LibraryProduct("liblalsupport", :liblalsupport; dont_dlopen = true),
    LibraryProduct("liblalsimulation", :liblalsimulation; dont_dlopen = true),
]

# The last serial HDF5_jll release avoids introducing an MPI runtime into LAL.
# It provides all four required platforms and the HDF5 API used by this release.
dependencies = [
    Dependency("FFTW_jll", v"3.3.11"; compat = "=3.3.11"),
    Dependency("GSL_jll", v"2.8.1"; compat = "=2.8.1"),
    Dependency("HDF5_jll", v"1.12.2"; compat = "=1.12.2"),
    Dependency("Zlib_jll", v"1.3.1"; compat = "=1.3.1"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.12", preferred_gcc_version = v"8",
)
