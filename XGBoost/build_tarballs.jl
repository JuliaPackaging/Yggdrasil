using BinaryBuilder, Pkg

# Collection of sources required to build Nettle
name = "XGBoost"
version = v"0.82"
sources = [
    "https://github.com/dmlc/xgboost.git"=>
    "3f83dcd50286d7c8d22e552942bd6572547c32b9",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost

git submodule init
git submodule update

# Patch dmlc-core to use case-sensitive windows.h includes
(cd dmlc-core && atomic_patch -p1 "${WORKSPACE}/srcdir/patches/dmlc_windows_h.patch")

# Because we're using OpenMP, we must use `gcc`
export CC=gcc
export CXX=g++

# For Linux, build using CMake
if [[ ${target} == *linux* ]]; then
    (mkdir build; cd build; cmake .. -DCMAKE_INSTALL_PREFIX=${prefix})
    make -C build -j ${nproc}
else
    if [[ ${target} == *mingw* ]]; then
        # Target Windows specifically
        EXTRA_FLAGS=(UNAME=Windows)
    fi
    
    # Otherwise, build with `make`, and do a minimal build
    cp make/minimum.mk config.mk
    make -j ${nproc} USE_OPENMP=1 ${EXTRA_FLAGS[@]}
fi

# Install
mkdir -p ${prefix}/{bin,include,lib}
cp -ra include/xgboost ${prefix}/include/
cp -a xgboost ${prefix}/bin/xgboost${exeext}

# Not every platform has a libxgboost.a
cp -a lib/libxgboost.a ${prefix}/lib || true

# We also need to bundle `libgomp`, so snarf it from the
# compiler support directory while we copy our main bundle of joy
if [[ ${target} == *mingw* ]]; then
    cp -a lib/xgboost.dll ${prefix}/bin
    cp -a /opt/${target}/${target}/lib*/libgomp*.${dlext} ${prefix}/bin
else
    cp -a lib/libxgboost.${dlext} ${prefix}/lib
    cp -a /opt/${target}/${target}/lib*/libgomp*.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Disable FreeBSD for now, because freebsd doesn't have backtrace()
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

