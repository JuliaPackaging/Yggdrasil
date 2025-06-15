# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)


name = "XDiag"
version = v"0.3.3"

include("../../L/libjulia/common.jl")

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awietek/xdiag.git", "a5f50e367e60c739360ad4f81d47ae1759d2e045")
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xdiag

Julia_PREFIX=${prefix}

# Redefining BLAS_LAPACK symbols to use with OpenBLAS
SYMB_DEFS=()
for sym in sasum dasum snrm2 dnrm2 sdot ddot sgemv dgemv cgemv zgemv sgemm dgemm cgemm zgemm ssyrk dsyrk cherk zherk; do
    SYMB_DEFS+=("-D${sym}=${sym}_64")
done

for sym in cgbcon cgbsv cgbsvx cgbtrf cgbtrs cgecon cgees cgeev cgeevx cgehrd cgels cgelsd cgemm cgemv cgeqp3 cgeqrf cgesdd cgesv cgesvd cgesvx cgetrf cgetri cgetrs cgges cggev cgtsv cgtsvx cheev cheevd cherk clangb clange clanhe clansy cpbtrf cpocon cposv cposvx cpotrf cpotri cpotrs cpstrf ctrcon ctrsyl ctrtri ctrtrs cungqr dasum ddot dgbcon dgbsv dgbsvx dgbtrf dgbtrs dgecon dgees dgeev dgeevx dgehrd dgels dgelsd dgemm dgemv dgeqp3 dgeqrf dgesdd dgesv dgesvd dgesvx dgetrf dgetri dgetrs dgges dggev dgtsv dgtsvx dlahqr dlangb dlange dlansy dlarnv dnrm2 dorgqr dpbtrf dpocon dposv dposvx dpotrf dpotri dpotrs dpstrf dstedc dsyev dsyevd dsyrk dtrcon dtrevc dtrsyl dtrtri dtrtrs ilaenv sasum sdot sgbcon sgbsv sgbsvx sgbtrf sgbtrs sgecon sgees sgeev sgeevx sgehrd sgels sgelsd sgemm sgemv sgeqrf sgeqp3 sgesdd sgesv sgesvd sgesvx sgetrf sgetri sgetrs sgges sggev sgtsv sgtsvx slahqr slangb slange slansy slarnv snrm2 sorgqr spbtrf spocon sposv sposvx spotrf spotri spotrs spstrf sstedc ssyev ssyevd ssyrk strcon strevc strsyl strtri strtrs zgbcon zgbsv zgbsvx zgbtrf zgbtrs zgecon zgees zgeev zgeevx zgehrd zgels zgelsd zgemm zgemv zgeqp3 zgeqrf zgesdd zgesv zgesvd zgesvx zgetrf zgetri zgetrs zgges zggev zgtsv zgtsvx zheev zheevd zherk zlangb zlange zlanhe zlansy zpbtrf zpocon zposv zposvx zpotrf zpotri zpotrs zpstrf ztrcon ztrsyl ztrtri ztrtrs zungqr; do
    SYMB_DEFS+=("-D${sym}=${sym}_64")
done

export CXXFLAGS="${SYMB_DEFS[@]} -DARMA_BLAS_LONG"

if [[ "${target}" == x86_64-apple-* ]]; then
    # Needed to get std::visit working  
    export MACOSX_DEPLOYMENT_TARGET=10.14
fi

# if [[ "${target}" == *-apple-* ]]; then
#     OMP_DEFINES=(-DOpenMP_libgomp_LIBRARY=${libdir}/libgomp.dylib -DOpenMP_ROOT=${libdir} -DOpenMP_CXX_LIB_NAMES="libgomp" -DOpenMP_CXX_FLAGS="-fopenmp=libgomp -Wno-unused-command-line-argument")
# fi

cmake -S . \
    -B build \
    -D XDIAG_DISABLE_HDF5=On \
    -DJulia_PREFIX=$Julia_PREFIX \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DXDIAG_JULIA_WRAPPER=On \
    -DCMAKE_PREFIX_PATH=$prefix \
    -DBLAS_LIBRARIES=${libdir}/libopenblas64_.${dlext} \
    -DLAPACK_LIBRARIES=${libdir}/libopenblas64_.${dlext} \
    "${OMP_DEFINES[@]}"

cmake --build build -j${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> (
    (os(p) == "linux" && libc(p) != "musl" && arch(p) == "x86_64") ||
    (os(p) == "linux" && libc(p) != "musl" && arch(p) == "aarch64") ||
    (os(p) == "macos" && arch(p) == "x86_64") ||
    (os(p) == "macos" && arch(p) == "aarch64") ||
    (os(p) == "windows" && arch(p) == "x86_64")) &&
    p.tags["julia_version"] !="1.6.3", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libxdiagjl", :libxdiagjl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.17")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat="0.14.3"),
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")), 
]

# Build the tarballs, and possibly a `build.jl` as well.
llvm_version = v"13.0.1+1"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0", preferred_llvm_version=llvm_version)
