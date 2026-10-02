using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "BART"
version = v"1.0.0"

sources = [
    GitSource("https://codeberg.org/mrirecon/bart.git", "37f3c5f0feaf0a19a7fca85c926ad74101f4a034"),
]

script = raw"""
# Supply C11 threads through the packaged glibc sysroot, as in Yggdrasil's systemd recipe.
if [[ -f "${prefix}/usr/include/threads.h" ]]; then
    glibc_root=$(dirname $(dirname $(dirname $(realpath "${prefix}/usr/include/threads.h"))))
    rsync --archive "${glibc_root}/" "/opt/${target}/${target}/sys-root/"
fi
cd ${WORKSPACE}/srcdir/bart

options=(
    AR="${target}-ar"
    AR_LOCK_NEEDED=0
    CUDA=0
    FFTW_BASE="${prefix}"
    BLAS_BASE="${prefix}"
    BLAS_L="-lopenblas"
    # FFTW_jll includes the threads API in libfftw3f.
    FFTW_L="-lfftw3f"
    LDFLAGS="-L${libdir} -fopenmp"
    # NUFFT interpolation relies on separately rounded products before index subtraction.
    OPT="-O2 -ffp-contract=off"
)
if [[ ${target} == *-apple-* ]]; then
    # BART detects Clang by name; its STL reader uses GCC's name for IEEE binary32.
    options+=(UNAME=Darwin MACPORTS=0 CC="${target}-clang -D_Float32=float")
fi
if [[ ${target} == aarch64-apple-* ]]; then
    # Complex division on Apple Silicon needs compiler-rt builtins.
    options+=(LIBS="-L${libdir}/darwin -lclang_rt.osx")
fi

${host_bindir}/make -j${nproc} "${options[@]}" bart
git diff --exit-code HEAD
install -Dvm755 bart "${bindir}/bart"
install_license LICENSE
"""

# BART uses fmemopen, which is absent from the default Intel macOS 10.12 SDK.
sources, script = require_macos_sdk("10.13", sources, script)

platforms = supported_platforms()
# The complete BART executable is supported upstream on Linux and macOS; Windows uses WSL.
filter!(p -> Sys.islinux(p) || Sys.isapple(p), platforms)
# BART includes execinfo.h unconditionally; musl does not provide that backtrace API.
filter!(p -> !Sys.islinux(p) || libc(p) == "glibc", platforms)
# The selected OpenBLAS32, libpng, and compiler-runtime baselines lack RISC-V artifacts.
filter!(p -> arch(p) != "riscv64", platforms)

products = [ExecutableProduct("bart", :bart)]

dependencies = [
    # BART's batched archive mode requires GNU Make 4.4.1 or newer.
    HostBuildDependency(PackageSpec(name="GNUMake_jll", version=v"4.4.1+0")),
    # The default glibc sysroots predate C11 threads.
    BuildDependency(PackageSpec(name="Glibc_jll", version=v"2.34.0+1");
        platforms=filter(Sys.islinux, platforms)),
    BuildDependency("LLVMCompilerRT_jll"; platforms=filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms)),
    Dependency("FFTW_jll"; compat="3.3.11"),
    # BART runs in a separate process without Julia's initialized BLAS backend.
    Dependency("OpenBLAS32_jll"; compat="0.3.23"),
    Dependency("libpng_jll"; compat="1.6.43"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5", platforms=filter(!Sys.isapple, platforms)),
    Dependency("LLVMOpenMP_jll"; compat="15.0.7", platforms=filter(Sys.isapple, platforms)),
]

# BART 1 requires GCC 12 or newer; macOS uses Clang.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"12", julia_compat="1.10")
