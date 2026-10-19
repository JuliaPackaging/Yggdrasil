using BinaryBuilder, Pkg
using Base.BinaryPlatforms

include(joinpath(@__DIR__, "..", "..", "platforms", "mpi.jl"))

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
export MPITRAMPOLINE_CC="${CC}"
export SOURCE_DATE_EPOCH=1790889543
if [[ ${target} == aarch64-apple-* ]]; then
    # Complex division on macOS ARM64 requires compiler-rt's __divdc3/__divsc3.
    export LDFLAGS="${LDFLAGS} -L${libdir}/darwin -lclang_rt.osx"
fi

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
# HDF5's Fortran runtime uses the supported libgfortran5 ABI.
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) == v"5", platforms)

products = [
    LibraryProduct("liblal", :liblal; dont_dlopen = true),
    LibraryProduct("liblalsupport", :liblalsupport; dont_dlopen = true),
    LibraryProduct("liblalsimulation", :liblalsimulation; dont_dlopen = true),
]

dependencies = [
    Dependency("FFTW_jll", v"3.3.11"; compat = "=3.3.11"),
    Dependency("GSL_jll", v"2.8.1"; compat = "=2.8.1"),
    Dependency("HDF5_jll", v"1.14.6"; compat = "=1.14.6"),
    Dependency("Zlib_jll", v"1.3.1"; compat = "=1.3.1"),
    Dependency("CompilerSupportLibraries_jll"; compat = "1"),
    BuildDependency(
        PackageSpec(name = "LLVMCompilerRT_jll", version = v"16.0.6");
        platforms = filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms),
    ),
]

# HDF5 1.14.6 predates the MPIABI variant. Match its three supported Unix ABIs.
mpi_platforms = AbstractPlatform[]
for (abi, package, compat) in (
        ("MPICH", "MPICH_jll", "4.3.0 - 4"),
        ("OpenMPI", "OpenMPI_jll", "=4.1.8"),
        ("MPItrampoline", "MPItrampoline_jll", "=5.5.3"),
    )
    variants = deepcopy(platforms)
    foreach(p -> p["mpi"] = abi, variants)
    append!(mpi_platforms, variants)
    push!(dependencies, Dependency(package; compat, platforms = variants))
end
platforms = mpi_platforms
push!(
    dependencies,
    RuntimeDependency(
        PackageSpec(name = "MPIPreferences", uuid = "3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
        compat = "0.1", top_level = true,
    ),
)
augment_platform_block = """
using Base.BinaryPlatforms
$(MPI.augment)
augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.12", preferred_gcc_version = v"8", augment_platform_block,
)
