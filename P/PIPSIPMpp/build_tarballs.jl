# BinaryBuilder recipe for PIPSIPMpp_jll
#
# Goes into Yggdrasil as  P/PIPSIPMpp/build_tarballs.jl
#
# Julia counterpart of the pipsipmpppy packaging:
#   pyproject.toml [tool.cibuildwheel]  -> the `platforms` matrix below
#   tools/build-libpips-variant.sh      -> `script` + MPI.augment_platforms
#   tools/cibw-repair.sh (auditwheel)   -> BinaryBuilder's Auditor (automatic)
#
# Local iteration (single platform, drops into a shell in the sandbox on failure):
#   julia +1.10 --project=. build_tarballs.jl --debug --verbose \
#         x86_64-linux-gnu-cxx11-mpi+openmpi

using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PIPSIPMpp"

# Tracks the upstream version from the root CMakeLists.txt
# (PIPSIPMpp_VERSION_MAJOR/MINOR/PATCH), which is also what pips_get_version()
# reports. Upstream bumps the minor on breaking C API changes, so PIPSIPMpp.jl
# can declare [compat] PIPSIPMpp_jll = "0.2" and let Pkg enforce statically what
# _check_abi verifies at load time.
version = v"0.2.0"

sources = [
    GitSource("https://gitlab.com/pips-ipmpp/pips-ipmpp.git",
              "74c5ed4e2f4334eed19184c84914067efe76e6b4"),

    # PIPS-IPM/Drivers/CMakeLists.txt unconditionally does
    # add_subdirectory(gams/gmspips), which needs the GDX sources even though we
    # only build the pips-ipmpp target. GitSource does not fetch submodules, so
    # GDX has to come in separately.
    GitSource("https://github.com/GAMS-dev/gdx.git",
              "fd8c1292973885cb6f8b689208b81b33b1270f26"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/pips-ipmpp

# Drop the GDX sources into place — see the note on the second GitSource above.
rm -rf ThirdPartyLibs/gdx
mv ${WORKSPACE}/srcdir/gdx ThirdPartyLibs/gdx

# Keep MPI from pulling in the deprecated C++ bindings. Without this the build
# links against libmpi_cxx, which does not exist under MPICH — the mpich and
# mpitrampoline variants would fail. Same guard as pipsipmpppy's CMakeLists.txt.
export CXXFLAGS="${CXXFLAGS} -DOMPI_SKIP_MPICXX -DMPICH_SKIP_MPICXX"

mkdir build && cd build

cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--as-needed" \
    -DWITH_MAKETEST=OFF

grep -q "HAVE_MUMPS.*TRUE\|MUMPS_D_LIBRARY:FILEPATH=.*dmumps" CMakeCache.txt || {
    echo "MUMPS not detected — build would silently fall back to MA57" >&2
    exit 1
}

# Check the configure output: it should end with
#   -- Found the following solvers:  MUMPS
# and no Panua-Pardiso. If Pardiso shows up, the source tree is not clean.

make -j${nproc} pips-ipmpp

# Upstream has no install rule for the shared library; it lands in
# build/PIPS-IPM/Core/ as libpips-ipmpp.so -> .so.0.2 -> .so.0.2.0.
# Copy the real file and let the Auditor recreate the soname links.
lib=$(find . -name "libpips-ipmpp.${dlext}*" -type f | head -n1)
if [ -z "${lib}" ]; then
    echo "libpips-ipmpp.${dlext} not found in the build tree" >&2
    find . -name "*.${dlext}*" >&2
    exit 1
fi
install -Dm755 "${lib}" "${libdir}/libpips-ipmpp.${dlext}"

# C interface headers, for non-Julia consumers of the JLL.
for hdr in $(find ../PIPS-IPM/Core/Interface -name '*.h'); do
    install -Dm644 "${hdr}" "${includedir}/$(basename ${hdr})"
done

install_license ../LICENSE
"""

# The augmentation block runs on the user's machine: it reads MPIPreferences and
# stamps the `mpi` tag onto the platform, so Pkg downloads the artifact built
# against the same MPI ABI as MPI.jl. This is what makes the MPI_Comm argument
# of pips_solver_create safe — an OpenMPI handle passed to an MPICH build would
# corrupt rather than error.
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)   # C++ code: std::string ABI matters

# PIPS-IPM++ is POSIX + MPI. No Windows, and no musl or 32-bit targets.
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
filter!(p -> libc(p) != "musl", platforms)

products = [
    LibraryProduct("libpips-ipmpp", :libpips_ipmpp),
]

# Derived from `ldd` on a working local build. PIPS parallelizes across MPI rank
# itself and uses MUMPS sequentially, hence MUMPS_seq_jll rather than MUMPS_jll.
dependencies = [
    Dependency(PackageSpec(name = "MUMPS_seq_jll")),
    # 32-bit integer BLAS/LAPACK. MUMPS_seq_jll goes through libblastrampoline,
    # so it resolves BLAS at run time and does not constrain this choice.
    Dependency(PackageSpec(name = "OpenBLAS32_jll")),
    # libgfortran, libquadmath, libgomp, libgcc_s
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll",
                           uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name = "Zlib_jll")),
    HostBuildDependency(PackageSpec(name = "CMake_jll")),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Drop combinations upstream does not provide, as COSMA and PETSc do.
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "i686"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" &&
                          (Sys.iswindows(p) || libc(p) == "musl")), platforms)

append!(dependencies, platform_dependencies)

# Keep MPItrampoline from looking for mpiwrapper.so when the Auditor dlopens the
# built libraries.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block,
               julia_compat = "1.10",
               preferred_gcc_version = v"9")