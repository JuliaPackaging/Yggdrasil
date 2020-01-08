## We'll use BinaryBuilder to build the Julia bindings and the scripts that are
## used for them.  Then, we'll set aside the built .jl files, modify them as
## necessary, and build the mlpack.jl project and push that to Github.

using BinaryBuilder

# Set sources and other environment variables.
name = "mlpack"
version = v"3.3.0-a1"
sources = [
    ("http://sourceforge.net/projects/arma/files/armadillo-9.800.3.tar.xz" =>
     "a481e1dc880b7cb352f8a28b67fe005dc1117d4341277f12999a2355d40d7599"),
    # Current git master branch as of 12/20/2019.
    # This will be replaced with the actual mlpack 3.3.0 release... but that
    # release is dependent on coherent Julia support, so this has to come
    # first...
    ("https://www.ratml.org/misc/mlpack-3.3.0-a1.tar.gz" =>
     "70b386c191465feff93d63ac299612e93eb943ea9144525108674ada037321cf")]
script = raw"""
    # Armadillo is already unpacked into srcdir/armadillo-*/.  We'll build it
    # but we won't use the wrapper; i.e., it will be a header-only library from
    # the perspective of mlpack.
    cd ${WORKSPACE}/srcdir/armadillo-*/
    sed --in-place 's/ARMA_USE_WRAPPER true/ARMA_USE_WRAPPER false/' CMakeLists.txt
    if [[ $target == i686*mingw* ]]
    then
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DBUILD_SHARED_LIBS=ON \
            .
    elif [[ $target == x86_64*mingw* ]]
    then
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -Dopenblas_LIBRARY=$prefix/lib/libopenblas64_.a \
            -DBUILD_SHARED_LIBS=ON \
            .
    else
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            .
    fi
    # Now the headers are in tmp/.

    # If we're on Windows, we need to find the exact location of the OpenBLAS
    # libraries.
    if [[ $target == *mingw* ]]
    then
        openblas_lib=`grep openblas_LIBRARY CMakeCache.txt |\
                      awk -F'=' '{ print $2 }' |\
                      sed 's/;$//'`;
    fi

    # Copy license to the correct place.
    cd ${WORKSPACE}/srcdir/mlpack-3.3.0-a1/
    mkdir -p $prefix/share/licenses/mlpack/
    cp LICENSE.txt $prefix/share/licenses/mlpack/

    # In order to convince mlpack to build Julia bindings, we have to use CMake
    # to specify the location of the Julia program.  But... it turns out that
    # all that CMake needs is some kind of executable program that prints the
    # version.  So we'll just create a crappy little script, since Julia may not
    # be available in the build environment...
    mkdir build
    cd build
    echo "#!/bin/bash" > julia
    echo "echo \"Fake Julia version 1.3.0\"" >> julia
    chmod +x julia

    if [[ $target == *apple* ]]
    then
        cmake \
            -DDEBUG=OFF \
            -DPROFILE=OFF \
            -DUSE_OPENMP=OFF \
            -DCMAKE_SYSTEM_NAME="Darwin" \
            -DBoost_NO_BOOST_CMAKE=1 \
            -DBUILD_JULIA_BINDINGS=ON \
            -DJULIA_EXECUTABLE=`pwd`/julia \
            -DBUILD_CLI_EXECUTABLES=OFF \
            -DBUILD_TESTS=OFF \
            -DARMADILLO_INCLUDE_DIR=${WORKSPACE}/srcdir/armadillo-9.800.3/tmp/include/ \
            -DCMAKE_INSTALL_PREFIX=$prefix \
            ..
    elif [[ $target == *mingw* ]]
    then
        # We need to remove bigobj support, but we also need to force the linker
        # to export all symbols because Windows DLLs have the concept of
        # "exported" and "not exported" functions.
        sed -i 's/-Wa,-mbig-obj/-Wl,--export-all-symbols/' ../CMakeLists.txt

        cmake \
            -DDEBUG=OFF \
            -DPROFILE=OFF \
            -DUSE_OPENMP=OFF \
            -DBoost_NO_BOOST_CMAKE=1 \
            -DBUILD_SHARED_LIBS=ON \
            -DBUILD_JULIA_BINDINGS=ON \
            -DJULIA_EXECUTABLE=`pwd`/julia \
            -DBUILD_CLI_EXECUTABLES=OFF \
            -DBUILD_TESTS=OFF \
            -DARMADILLO_INCLUDE_DIR=${WORKSPACE}/srcdir/armadillo-9.800.3/tmp/include/ \
            -DLAPACK_LIBRARY=$openblas_lib \
            -DBLAS_LIBRARY=$openblas_lib \
            -DCMAKE_INSTALL_PREFIX=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            ..
    else
        cmake \
            -DDEBUG=OFF \
            -DPROFILE=OFF \
            -DUSE_OPENMP=OFF \
            -DBoost_NO_BOOST_CMAKE=1 \
            -DBUILD_JULIA_BINDINGS=ON \
            -DJULIA_EXECUTABLE=`pwd`/julia \
            -DBUILD_CLI_EXECUTABLES=OFF \
            -DBUILD_TESTS=OFF \
            -DARMADILLO_INCLUDE_DIR=${WORKSPACE}/srcdir/armadillo-9.800.3/tmp/include/ \
            -DCMAKE_INSTALL_PREFIX=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            ..
    fi
    make -j2
    make install

    libdir=`find $prefix -iname 'lib*' -type d -maxdepth 1 | head -1`;
    if [[ $target == *apple* ]]
    then
        cp -v src/mlpack/bindings/julia/mlpack/src/*.dylib $libdir/
    elif [[ $target == *mingw* ]]
    then
        cp -v libmlpack_julia*.dll.a $libdir/
        cp -v libmlpack_julia*.dll $prefix/bin/
    else
        cp -v src/mlpack/bindings/julia/mlpack/src/*.so $libdir/
    fi

    ls $prefix
    ls $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()
# Seems like boost_jll doesn't exist for FreeBSD, so we have to remove it.
filter!(e -> e != FreeBSD(:x86_64), platforms)

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
    "OpenBLAS_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
