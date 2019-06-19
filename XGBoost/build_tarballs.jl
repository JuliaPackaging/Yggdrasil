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

# For Linux, build using CMake
if [[ ${target} == *linux* ]]; then
    mkdir build
    (cd build; cmake .. -DCMAKE_INSTALL_PREFIX=${prefix})
    make -C build -j ${nproc}
elif [[ ${target} == *mingw* ]]; then
    # Windows has a special makefile because of course it does
    #cp make/mingw64.mk config.mk
    cp make/minimum.mk config.mk
    make -j ${nproc} UNAME=Windows USE_OPENMP=1
else
    # Otherwise, build with `make`, and do a minimal build
    cp make/minimum.mk config.mk
    make -j ${nproc}
fi

# Install
mkdir -p ${prefix}/{bin,include,lib}
cp -ra include/xgboost ${prefix}/include/
cp -a xgboost ${prefix}/bin

# Not every platform has a libxgboost.a
cp -a lib/libxgboost.a ${prefix}/lib || true
if [[ ${target} == *mingw* ]]; then
    cp -a lib/xgboost.dll ${prefix}/bin
else
    cp -a lib/libxgboost.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable FreeBSD for now, because freebsd doesn't have backtrace()
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

