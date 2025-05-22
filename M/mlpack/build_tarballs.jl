## We'll use BinaryBuilder to build the Julia bindings and the scripts that are
## used for them.  Then, we'll set aside the built .jl files, modify them as
## necessary, and build the mlpack.jl project and push that to Github.

using BinaryBuilder

# Set sources and other environment variables.
name = "mlpack"
source_version = v"4.6.2"
version = source_version
sources = [
    ArchiveSource("https://www.mlpack.org/files/mlpack-$(source_version).tar.gz",
                  "2fe772da383a935645ced07a07b51942ca178d38129df3bf685890bc3c1752cf"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                  "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")
]

script = raw"""
cd ${WORKSPACE}/srcdir/mlpack-*/

# On macOS, we need to compile with 10.14 as a target to work around
# std::optional availability issues.
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

mkdir build && cd build

# In order to convince mlpack to build Julia bindings, we have to use CMake
# to specify the location of the Julia program.  But... it turns out that
# all that CMake needs is some kind of executable program that prints the
# version.  So we'll just create a crappy little script, since Julia may not
# be available in the build environment.
echo "#!/bin/bash" > julia
echo "echo \"Fake Julia version 1.9.4\"" >> julia
chmod +x julia

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_CROSSCOMPILING=OFF
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DUSE_OPENMP=ON
       -DBUILD_JULIA_BINDINGS=ON
       -DBUILD_SHARED_LIBS=ON
       -DJULIA_EXECUTABLE="${PWD}/julia"
       -DBUILD_CLI_EXECUTABLES=OFF
       -DBUILD_GO_BINDINGS=OFF
       -DBUILD_R_BINDINGS=OFF
       -DBUILD_PYTHON_BINDINGS=OFF
       -DBUILD_TESTS=OFF)

if [[ "${nbits}" == 64 ]]; then
    # We need to rename some functions for compatibility with Julia's OpenBLAS
    SYMB_DEFS=()
    for sym in cgbcon cgbsv cgbsvx cgbtrf cgbtrs cgecon cgees cgeev cgeevx cgehrd cgels cgelsd cgemm cgemv cgeqp3 cgeqrf cgesdd cgesv cgesvd cgesvx cgetrf cgetri cgetrs cgges cggev cgtsv cgtsvx checon cheev cheevd cherk chetrf chetri chetrs clangb clange clanhe clansy cpbtrf cpocon cposv cposvx cpotrf cpotri cpotrs cpstrf ctrcon ctrsyl ctrtri ctrtrs cungqr dasum ddot dgbcon dgbsv dgbsvx dgbtrf dgbtrs dgecon dgees dgeev dgeevx dgehrd dgels dgelsd dgemm dgemv dgeqp3 dgeqrf dgesdd dgesv dgesvd dgesvx dgetrf dgetri dgetrs dgges dggev dgtsv dgtsvx dlahqr dlangb dlange dlansy dlarnv dnrm2 dorgqr dpbtrf dpocon dposv dposvx dpotrf dpotri dpotrs dpstrf dstedc dsycon dsyev dsyevd dsyrk dsytrf dsytri dsytrs dtrcon dtrevc dtrsyl dtrtri dtrtrs ilaenv sasum sdot sgbcon sgbsv sgbsvx sgbtrf sgbtrs sgecon sgees sgeev sgeevx sgehrd sgels sgelsd sgemm sgemv sgeqrf sgeqp3 sgesdd sgesv sgesvd sgesvx sgetrf sgetri sgetrs sgges sggev sgtsv sgtsvx slahqr slangb slange slansy slarnv snrm2 sorgqr spbtrf spocon sposv sposvx spotrf spotri spotrs spstrf sstedc ssycon ssyev ssyevd ssyrk ssytrf ssytri ssytrs strcon strevc strsyl strtri strtrs zgbcon zgbsv zgbsvx zgbtrf zgbtrs zgecon zgees zgeev zgeevx zgehrd zgels zgelsd zgemm zgemv zgeqp3 zgeqrf zgesdd zgesv zgesvd zgesvx zgetrf zgetri zgetrs zgges zggev zgtsv zgtsvx zhecon zheev zheevd zherk zhetrf zhetri zhetrs zlangb zlange zlanhe zlansy zpbtrf zpocon zposv zposvx zpotrf zpotri zpotrs zpstrf ztrcon ztrsyl ztrtri ztrtrs zungqr; do
        SYMB_DEFS+=("-D${sym}=${sym}_64")
    done
    export CXXFLAGS="${SYMB_DEFS[@]}"
fi

if [[ $target == *powerpc* ]]; then
    FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-L/opt/${target}/${target}/lib${arch_ext}/ -lgomp -pthread -ldl")
fi

if [[ $target == *apple* ]]; then
    FLAGS+=(-DCMAKE_SYSTEM_NAME="Darwin")
elif [[ $target == *mingw* ]]; then
    # We need to remove bigobj support, but we also need to force the linker
    # to export all symbols because Windows DLLs have the concept of
    # "exported" and "not exported" functions.
    sed -i 's/-Wa,-mbig-obj/-Wl,--export-all-symbols/' ../CMakeLists.txt

    # For Windows configuration, we need to manually specify the OpenBLAS
    # libraries as CMake variables.
    if [[ "${nbits}" == 64 ]]; then
        arch_ext="64_";
    else
        arch_ext="";
    fi
    FLAGS+=(-DLAPACK_LIBRARY=${libdir}/libopenblas${arch_ext}.${dlext})
    FLAGS+=(-DBLAS_LIBRARY=${libdir}/libopenblas${arch_ext}.${dlext})
fi

if [[ ${target} != *darwin* ]]; then
    # Needed to find libgfortran for OpenBLAS.
    export CXXFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib -Wl,-rpath-link,/opt/${target}/${target}/lib64 ${CXXFLAGS}"
fi

# Reduce number of cores used for builds on FreeBSD or ARM (they run out of
# memory).
if [[ $target == *freebsd* ]] || [[ $target == *arm* ]] || [[ $target == *mingw* ]]; then
  nproc=1;
fi

cmake .. "${FLAGS[@]}"
make -j${nproc}
make install

if [[ ${target} == *mingw* ]]; then
    cp -v libmlpack_julia*.dll "${libdir}"
else
    cp -v src/mlpack/bindings/julia/mlpack/src/*.${dlext} "${libdir}"
fi

install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = expand_cxxstring_abis(supported_platforms())
# We're missing some dependencies for this platform, exclude it for the time being
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built.
products = [
    # Utility library with functionality to call the mlpack::CLI singleton.
    LibraryProduct("libmlpack_julia_util", :libmlpack_julia_util),
    # Each of these contains a mlpackMain() implementation for the given
    # binding.
    LibraryProduct("libmlpack_julia_adaboost", :libmlpack_julia_adaboost),
    LibraryProduct("libmlpack_julia_approx_kfn", :libmlpack_julia_approx_kfn),
    LibraryProduct("libmlpack_julia_bayesian_linear_regression",
        :libmlpack_julia_bayesian_linear_regression),
    LibraryProduct("libmlpack_julia_cf", :libmlpack_julia_cf),
    LibraryProduct("libmlpack_julia_dbscan", :libmlpack_julia_dbscan),
    LibraryProduct("libmlpack_julia_decision_tree",
        :libmlpack_julia_decision_tree),
    LibraryProduct("libmlpack_julia_det", :libmlpack_julia_det),
    LibraryProduct("libmlpack_julia_emst", :libmlpack_julia_emst),
    LibraryProduct("libmlpack_julia_fastmks", :libmlpack_julia_fastmks),
    LibraryProduct("libmlpack_julia_gmm_generate",
        :libmlpack_julia_gmm_generate),
    LibraryProduct("libmlpack_julia_gmm_probability",
        :libmlpack_julia_gmm_probability),
    LibraryProduct("libmlpack_julia_gmm_train", :libmlpack_julia_gmm_train),
    LibraryProduct("libmlpack_julia_hmm_generate",
        :libmlpack_julia_hmm_generate),
    LibraryProduct("libmlpack_julia_hmm_loglik", :libmlpack_julia_hmm_loglik),
    LibraryProduct("libmlpack_julia_hmm_train", :libmlpack_julia_hmm_train),
    LibraryProduct("libmlpack_julia_hmm_viterbi", :libmlpack_julia_hmm_viterbi),
    LibraryProduct("libmlpack_julia_hoeffding_tree",
        :libmlpack_julia_hoeffding_tree),
    LibraryProduct("libmlpack_julia_image_converter",
        :libmlpack_julia_image_converter),
    LibraryProduct("libmlpack_julia_kde", :libmlpack_julia_kde),
    LibraryProduct("libmlpack_julia_kernel_pca", :libmlpack_julia_kernel_pca),
    LibraryProduct("libmlpack_julia_kfn", :libmlpack_julia_kfn),
    LibraryProduct("libmlpack_julia_kmeans", :libmlpack_julia_kmeans),
    LibraryProduct("libmlpack_julia_knn", :libmlpack_julia_knn),
    LibraryProduct("libmlpack_julia_krann", :libmlpack_julia_krann),
    LibraryProduct("libmlpack_julia_lars", :libmlpack_julia_lars),
    LibraryProduct("libmlpack_julia_linear_regression",
        :libmlpack_julia_linear_regression),
    LibraryProduct("libmlpack_julia_linear_svm", :libmlpack_julia_linear_svm),
    LibraryProduct("libmlpack_julia_lmnn", :libmlpack_julia_lmnn),
    LibraryProduct("libmlpack_julia_local_coordinate_coding",
        :libmlpack_julia_local_coordinate_coding),
    LibraryProduct("libmlpack_julia_logistic_regression",
        :libmlpack_julia_logistic_regression),
    LibraryProduct("libmlpack_julia_lsh", :libmlpack_julia_lsh),
    LibraryProduct("libmlpack_julia_mean_shift", :libmlpack_julia_mean_shift),
    LibraryProduct("libmlpack_julia_nbc", :libmlpack_julia_nbc),
    LibraryProduct("libmlpack_julia_nca", :libmlpack_julia_nca),
    LibraryProduct("libmlpack_julia_nmf", :libmlpack_julia_nmf),
    LibraryProduct("libmlpack_julia_pca", :libmlpack_julia_pca),
    LibraryProduct("libmlpack_julia_perceptron", :libmlpack_julia_perceptron),
    LibraryProduct("libmlpack_julia_preprocess_binarize",
        :libmlpack_julia_preprocess_binarize),
    LibraryProduct("libmlpack_julia_preprocess_describe",
        :libmlpack_julia_preprocess_describe),
    LibraryProduct("libmlpack_julia_preprocess_one_hot_encoding",
        :libmlpack_julia_preprocess_one_hot_encoding),
    LibraryProduct("libmlpack_julia_preprocess_scale",
        :libmlpack_julia_preprocess_scale),
    LibraryProduct("libmlpack_julia_preprocess_split",
        :libmlpack_julia_preprocess_split),
    LibraryProduct("libmlpack_julia_radical", :libmlpack_julia_radical),
    LibraryProduct("libmlpack_julia_random_forest",
        :libmlpack_julia_random_forest),
    LibraryProduct("libmlpack_julia_softmax_regression",
        :libmlpack_julia_softmax_regression),
    LibraryProduct("libmlpack_julia_sparse_coding",
        :libmlpack_julia_sparse_coding)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("armadillo_jll"; compat="14.4.1"),
    Dependency("OpenBLAS_jll"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    # These are header-only libraries just needed for the build process.
    BuildDependency("cereal_jll"),
    BuildDependency("ensmallen_jll"),
    BuildDependency("stb_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.7")
