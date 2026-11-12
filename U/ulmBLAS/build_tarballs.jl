# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "ulmBLAS"
version = v"0.3.0"

sources = [
    GitSource("https://github.com/michael-lehn/ulmBLAS.git",
              "58e67dc8a19b385b33935750e58792db3e9de5e5"; tag="v$(version)"),
]

# One library per instruction set, `libulmblas_VARIANT`, with the BLAS
# interface for libblastrampoline (ILP64, suffix `64_`), GEMM with
# arbitrary strides (`ulmblas_dgemm_strided`, ...) and the LAPACK functions
# ?getrf, ?potrf, solves and inverses with OpenMP tasks (number of threads:
# `ulmblas_set_num_threads_64_`).  UlmBLAS.jl selects the variant for the
# CPU at run time.
script = raw"""
cd ${WORKSPACE}/srcdir/ulmBLAS

flags() {
    case $1 in
    neon)     echo "-DULMBLAS_NO_SME";;
    sme)      echo "-mcpu=apple-m4";;
    x86_64)   echo "-msse3";;
    haswell)  echo "-mavx -mavx2 -mfma" \
                   "-DULMBLAS_DGEMM_UKERNEL_openblas_haswell_4x8" \
                   "-DULMBLAS_SGEMM_UKERNEL_openblas_haswell_8x4" \
                   "-DULMBLAS_CGEMM_UKERNEL_openblas_haswell_8x2" \
                   "-DULMBLAS_ZGEMM_UKERNEL_openblas_haswell_4x2";;
    skylakex) echo "-mavx -mavx2 -mfma -mavx512f -mavx512dq" \
                   "-DULMBLAS_DGEMM_UKERNEL_openblas_skylakex_16x12" \
                   "-DULMBLAS_SGEMM_UKERNEL_openblas_skylakex_16x4" \
                   "-DULMBLAS_CGEMM_UKERNEL_openblas_skylakex_8x2" \
                   "-DULMBLAS_ZGEMM_UKERNEL_blis_zen4_12x4";;
    zen4)     echo "-mavx -mavx2 -mfma -mavx512f -mavx512dq" \
                   "-DULMBLAS_DGEMM_UKERNEL_blis_zen4_32x6" \
                   "-DULMBLAS_SGEMM_UKERNEL_openblas_skylakex_16x4" \
                   "-DULMBLAS_CGEMM_UKERNEL_openblas_skylakex_8x2" \
                   "-DULMBLAS_ZGEMM_UKERNEL_blis_zen4_12x4";;
    esac
}

for v in ${variants}; do
    build=${WORKSPACE}/build/${v}
    # The makefile picks these with `uname`, i.e. for the build host.
    if [[ ${target} == *-apple-* ]]; then
        link="-dynamiclib -Wl,-force_load,${build}/liblbtblas.a"
        link+=" -Wl,-force_load,${build}/liblbtlapack.a"
        if [[ ${v} == sme ]]; then
            # the SME support routines (`__arm_tpidr2_save`, ...), linked statically
            link+=" -L${libdir}/darwin -lclang_rt.osx"
        fi
        # libomp of LLVMOpenMP_jll
        omp="OMPFLAGS=-fopenmp -I${includedir}"
        omplibs="OMPLIBS=-L${libdir} -lomp"
    else
        link="-shared -Wl,--whole-archive ${build}/liblbtblas.a ${build}/liblbtlapack.a -Wl,--no-whole-archive"
        link+=" -static-libstdc++ -static-libgcc -Wl,--no-undefined -Wl,--strip-debug"
        # don't export the static libstdc++ (MinGW exports all global symbols)
        link+=" -Wl,--exclude-libs,libstdc++.a:libgcc.a:libgcc_eh.a"
        # libgomp of CompilerSupportLibraries_jll
        omp="OMPFLAGS=-fopenmp"
        omplibs="OMPLIBS=-fopenmp"
    fi
    make -j${nproc} lbt CXX="${CXX}" CC="${CC}" ARCHFLAGS="$(flags ${v})" \
         OPENMP=1 LAPACK=1 "${omp}" "${omplibs}" \
         BUILD_DIR=${build} LBT_LIB=${build}/libulmblas_${v}.${dlext} LBT_LINK="${link}"
    install -Dvm 755 ${build}/libulmblas_${v}.${dlext} ${libdir}/libulmblas_${v}.${dlext}
done

# includes the licenses of the micro kernels from BLIS, AOCL-BLAS and OpenBLAS
install_license LICENSE
if [[ ${target} == *-apple-* ]]; then
    # compiler-rt is linked statically into libulmblas_sme
    install_license ${prefix}/share/licenses/LLVMCompilerRT/LICENSE.TXT
fi
"""

platforms = supported_platforms()
# UlmBLAS.jl selects variants only on x86-64 and AArch64; other architectures
# (portable reference kernels only) are not built or tested yet.
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
# Not built or tested yet: the NEON variant on Linux and Windows.
filter!(p -> !(!Sys.isapple(p) && arch(p) == "aarch64"), platforms)
# Not built or tested yet: the x86-64 variants on macOS.
filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)
# Not built or tested yet: FreeBSD and musl.
filter!(p -> !Sys.isfreebsd(p) && libc(p) != "musl", platforms)

# macOS: NEON for all Apple silicon, SME2 for Apple M4 and later.
variants(p) = Sys.isapple(p) ? ["neon", "sme"] : ["x86_64", "haswell", "skylakex", "zen4"]

# Not loaded with the JLL: only some variants run on a given CPU.
products(p) = [LibraryProduct("libulmblas_$(v)", Symbol("libulmblas_$(v)"); dont_dlopen=true)
               for v in variants(p)]

# The OpenMP runtime: libomp on macOS, libgomp on Linux and Windows.
# LLVMCompilerRT_jll is only needed to link libulmblas_sme.  One list for
# all platforms (with `platforms`): the JLL gets its dependencies from it.
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               compat="1.0.5", platforms=filter(!Sys.isapple, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               compat="15.0.7 - 23", platforms=filter(Sys.isapple, platforms)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", version="20.1.8");
                    platforms=filter(Sys.isapple, platforms)),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue
    # GCC 11 is the oldest GCC without broad slowdowns (GCC 10: dgemv up to 27%,
    # GCC 6: zgemm up to 2.8x in the SSE3 variant); GCC 5 fails.  With GCC 11
    # only zgemv without transposition is slower than with GCC 14 (about 3x).
    # libstdc++ is linked statically.  The OpenMP tasks need OpenMP 5.0
    # (iterators in depend clauses): GCC 9 or newer.
    compilers = Sys.isapple(platform) ? (;) : (; preferred_gcc_version=v"11")
    build_tarballs(ARGS, name, version, sources,
                   "variants=\"$(join(variants(platform), ' '))\"\n" * script,
                   [platform], products(platform), dependencies;
                   julia_compat="1.9",
                   # The variants choose their instruction sets.
                   lock_microarchitecture=false,
                   compilers...)
end
