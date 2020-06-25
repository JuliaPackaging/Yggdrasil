using BinaryBuilder, Pkg

# Collection of sources required to build XGBoost
name = "XGBoost"
version = v"1.1.1"
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","34408a7fdcebc0e32142ed2f52156ea65d813400"), 
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule init
git submodule update

# Patch dmlc-core to use case-sensitive windows.h includes
(cd dmlc-core; atomic_patch -p1 "${WORKSPACE}/srcdir/patches/dmlc_windows.patch")

# For Linux, build using CMake
if [[ ${target} == *linux* ]] ||  [[ ${target} == *mingw* ]]; then
    (mkdir build; cd build; cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
    make -C build -j ${nproc}
# For Mac and FreeBSD, build without openmp
elif [[ ${target} == *darwin* ]] ||  [[ ${target} == *freebsd* ]]; then
    (mkdir build; cd build; cmake .. -DUSE_OPENMP=OFF -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
    make -C build -j ${nproc}
fi

# Install
mkdir -p ${prefix}/{bin,include,lib}
cp -ra include/xgboost ${prefix}/include/
cp -a xgboost${exeext} ${prefix}/bin/xgboost${exeext}

if [[ ${target} == *mingw* ]]; then
    cp -a lib/xgboost.dll ${prefix}/bin
else
    cp -a lib/libxgboost.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Disable powerpc for now
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]
# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
