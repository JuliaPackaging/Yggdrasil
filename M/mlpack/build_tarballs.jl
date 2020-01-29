## We'll use BinaryBuilder to build the Julia bindings and the scripts that are
## used for them.  Then, we'll set aside the built .jl files, modify them as
## necessary, and build the mlpack.jl project and push that to Github.

using BinaryBuilder

# Set sources and other environment variables.
name = "mlpack"
version = v"3.3.0-a1"
sources = [
    # Current git master branch as of 12/20/2019.
    # This will be replaced with the actual mlpack 3.3.0 release... but that
    # release is dependent on coherent Julia support, so this has to come
    # first...
    "https://www.ratml.org/misc/mlpack-3.3.0-a1.tar.gz" =>
    "70b386c191465feff93d63ac299612e93eb943ea9144525108674ada037321cf"
]

script = raw"""
cd ${WORKSPACE}/srcdir/mlpack-*/

mkdir build && cd build

# In order to convince mlpack to build Julia bindings, we have to use CMake
# to specify the location of the Julia program.  But... it turns out that
# all that CMake needs is some kind of executable program that prints the
# version.  So we'll just create a crappy little script, since Julia may not
# be available in the build environment...
echo "#!/bin/bash" > julia
echo "echo \"Fake Julia version 1.3.0\"" >> julia
chmod +x julia

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DBUILD_SHARED_LIBS=ON
       -DDEBUG=OFF
       -DPROFILE=OFF
       -DUSE_OPENMP=OFF
       -DBoost_NO_BOOST_CMAKE=1
       -DBUILD_JULIA_BINDINGS=ON
       -DJULIA_EXECUTABLE="${PWD}/julia"
       -DBUILD_CLI_EXECUTABLES=OFF
       -DBUILD_TESTS=OFF)

if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64* ]]; then
    # We need to rename some functions for compatibility with Julia's OpenBLAS
    SYMB_DEFS=()
    for sym in cgbcon cgbsv cgbsvx cgbtrf cgbtrs cgecon cgees cgeev cgeevx cgehrd cgels cgelsd cgemm cgemv cgeqrf cgesdd cgesv cgesvd cgesvx cgetrf cgetri cgetrs cgges cggev cgtsv cgtsvx cheev cheevd cherk clangb clange clanhe clansy cpbtrf cpocon cposv cposvx cpotrf cpotri cpotrs ctrcon ctrsyl ctrtri ctrtrs cungqr dasum ddot dgbcon dgbsv dgbsvx dgbtrf dgbtrs dgecon dgees dgeev dgeevx dgehrd dgels dgelsd dgemm dgemv dgeqrf dgesdd dgesv dgesvd dgesvx dgetrf dgetri dgetrs dgges dggev dgtsv dgtsvx dlahqr dlangb dlange dlansy dlarnv dnrm2 dorgqr dpbtrf dpocon dposv dposvx dpotrf dpotri dpotrs dstedc dsyev dsyevd dsyrk dtrcon dtrevc dtrsyl dtrtri dtrtrs ilaenv sasum sdot sgbcon sgbsv sgbsvx sgbtrf sgbtrs sgecon sgees sgeev sgeevx sgehrd sgels sgelsd sgemm sgemv sgeqrf sgesdd sgesv sgesvd sgesvx sgetrf sgetri sgetrs sgges sggev sgtsv sgtsvx slahqr slangb slange slansy slarnv snrm2 sorgqr spbtrf spocon sposv sposvx spotrf spotri spotrs sstedc ssyev ssyevd ssyrk strcon strevc strsyl strtri strtrs zgbcon zgbsv zgbsvx zgbtrf zgbtrs zgecon zgees zgeev zgeevx zgehrd zgels zgelsd zgemm zgemv zgeqrf zgesdd zgesv zgesvd zgesvx zgetrf zgetri zgetrs zgges zggev zgtsv zgtsvx zheev zheevd zherk zlangb zlange zlanhe zlansy zpbtrf zpocon zposv zposvx zpotrf zpotri zpotrs ztrcon ztrsyl ztrtri ztrtrs zungqr; do
        SYMB_DEFS+=("-D${sym}=${sym}_64")
    done
    export CXXFLAGS="${SYMB_DEFS[@]}"
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
        arch_ext="_64";
    else
        arch_ext="";
    fi
    FLAGS+=(-DLAPACK_LIBRARY=/opt/${target}/${target}/lib/libopenblas${arch_ext}.${dlext})
    FLAGS+=(-DBLAS_LIBRARY=/opt/${target}/${target}/lib/libopenblas${arch_ext}.${dlext})
fi

if [[ ${target} != *darwin* ]]; then
    # Needed to find libgfortran for OpenBLAS.
    export CXXFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib -Wl,-rpath-link,/opt/${target}/${target}/lib64 ${CXXFLAGS}"
fi

# Reduce number of cores used for builds on FreeBSD or ARM (they run out of
# memory).
if [[ $target == *freebsd* ]] || [[ $target == *arm* ]]; then
  nproc=1;
fi

cmake .. "${FLAGS[@]}"
make -j${nproc}
make install

if [[" ${target}" == *mingw* ]]; then
    cp -v libmlpack_julia*.dll.a "${prefix}/lib"
    cp -v libmlpack_julia*.dll "${libdir}"
else
    cp -v src/mlpack/bindings/julia/mlpack/src/*.${dlext} "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = expand_cxxstring_abis(supported_platforms())
#print(platforms)
platforms = Platform[Windows(:i686, compiler_abi=CompilerABI(cxxstring_abi=:cxx03))]

# The products that we will ensure are always built.
products = [
    # The main mlpack library.
    LibraryProduct("libmlpack", :libmlpack),
    # Utility library with functionality to call the mlpack::CLI singleton.
    LibraryProduct("libmlpack_julia_util", :libmlpack_julia_util),
    # Each of these contains a mlpackMain() implementation for the given binding.
    LibraryProduct("libmlpack_julia_adaboost", :libmlpack_julia_adaboost),
    LibraryProduct("libmlpack_julia_approx_kfn", :libmlpack_julia_approx_kfn),
    LibraryProduct("libmlpack_julia_cf", :libmlpack_julia_cf),
    LibraryProduct("libmlpack_julia_dbscan", :libmlpack_julia_dbscan),
    LibraryProduct("libmlpack_julia_decision_stump",
        :libmlpack_julia_decision_stump),
    LibraryProduct("libmlpack_julia_decision_tree",
        :libmlpack_julia_decision_tree),
    LibraryProduct("libmlpack_julia_det", :libmlpack_julia_det),
    LibraryProduct("libmlpack_julia_emst", :libmlpack_julia_emst),
    LibraryProduct("libmlpack_julia_fastmks", :libmlpack_julia_fastmks),
    LibraryProduct("libmlpack_julia_gmm_generate",
        :libmlpack_julia_gmm_generate),
    LibraryProduct("libmlpack_julia_gmm_probability",
        :libmlpack_gmm_probability),
    LibraryProduct("libmlpack_julia_gmm_train", :libmlpack_julia_gmm_train),
    LibraryProduct("libmlpack_julia_hmm_generate",
        :libmlpack_julia_hmm_generate),
    LibraryProduct("libmlpack_julia_hmm_loglik", :libmlpack_julia_hmm_loglik),
    LibraryProduct("libmlpack_julia_hmm_train", :libmlpack_julia_hmm_train),
    LibraryProduct("libmlpack_julia_hmm_viterbi", :libmlpack_julia_hmm_viterbi),
    LibraryProduct("libmlpack_julia_hoeffding_tree",
        :libmlpack_julia_hoeffding_tree),
    LibraryProduct("libmlpack_julia_kernel_pca", :libmlpack_julia_kernel_pca),
    LibraryProduct("libmlpack_julia_kfn", :libmlpack_julia_kfn),
    LibraryProduct("libmlpack_julia_kmeans", :libmlpack_julia_kmeans),
    LibraryProduct("libmlpack_julia_knn", :libmlpack_julia_knn),
    LibraryProduct("libmlpack_julia_krann", :libmlpack_julia_krann),
    LibraryProduct("libmlpack_julia_lars", :libmlpack_julia_lars),
    LibraryProduct("libmlpack_julia_linear_regression",
        :libmlpack_julia_linear_regression),
    LibraryProduct("libmlpack_julia_lmnn", :libmlpack_julia_lmnn),
    LibraryProduct("libmlpack_julia_local_coordinate_coding",
        :libmlpack_julia_local_coordinate_coding),
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
    "boost_jll",
    "armadillo_jll",
    "OpenBLAS_jll" # Is this necessary?
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
