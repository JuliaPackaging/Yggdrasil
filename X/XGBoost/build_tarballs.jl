using BinaryBuilder, Pkg

# Collection of sources required to build XGBoost
name = "XGBoost"
version = v"1.0.2"
sources = [
    GitSource("https://github.com/dmlc/xgboost.git", "917b0a7b46954e9be36cbc430a1727bb093234bb")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost

git submodule init
git submodule update

#if [[ ${target} == *mingw* ]]; then
    # Target Windows specifically
    #EXTRA_FLAGS=(UNAME=Windows)
#fi

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
make -j ${nproc} USE_OPENMP=0 USE_HDFS=0 USE_S3=0 USE_AZURE=0 LIB_RABIT=librabit_empty.a ${EXTRA_FLAGS[@]}
make install

# Install
#mkdir -p ${prefix}/{bin,include,lib}
#cp -ra include/xgboost ${prefix}/include/
#cp -a xgboost ${prefix}/bin/xgboost${exeext}

# Not every platform has a libxgboost.a
#cp -a lib/libxgboost.a ${prefix}/lib || true

# We also need to bundle `libgomp`, so snarf it from the
# compiler support directory while we copy our main bundle of joy
if [[ ${target} == *mingw* ]]; then
    cp -a lib/xgboost.dll ${prefix}/bin
#    cp -a /opt/${target}/${target}/lib*/libgomp*.${dlext} ${prefix}/bin
else
    cp -a lib/libxgboost.${dlext} ${prefix}/lib
#    cp -a /opt/${target}/${target}/lib*/libgomp*.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Disable various platforms that do not build
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]
platforms = [p for p in platforms if !(libc(p) == :musl)]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
