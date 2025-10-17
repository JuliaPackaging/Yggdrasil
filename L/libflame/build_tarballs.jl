name = "libflame"

using BinaryBuilder, Pkg

version = v"5.2.0"

# Collection of sources required to build lapack
sources = [
    GitSource("https://github.com/flame/libflame",
              "646ed9075cc45aeffb53632a3ec88defb423fefa"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all *64-bit* platforms
# We try to maintain consistency with the blis Yggdrasil build scripts.

script = raw"""
cd $WORKSPACE/srcdir/libflame

# We might need newer `config.guess`` and `config.sub` files
update_configure_scripts

extra_flags=" --disable-static-build "

if [[ "${target}" == *-apple-* ]]; then
    extra_flags=" --enable-static-build "
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mac-update-makefile.patch
fi

if [[ "${target}" == *-w64-mingw32* ]]; then
    extra_flags+=" --enable-windows-build "
    # disable time & clock functions on windows (mingw): sys/times.h is missing
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows-remove-time.patch
    # update the make build scripts for windows cross-compiling with gcc:
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows-update-build.patch
fi

if [[ "${target}" == *mingw* ]]; then
    LBT="-L${libdir} -lblastrampoline-5"
else
    LBT="-L${libdir} -lblastrampoline"
fi

# - Compile and build a LAPACK compatibility layer with --enable-lapack2flame
# - If a static library is not needed, use --disable-static-build
# - Enable a dynamic build with --enable-dynamic-build
./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-multithreading=openmp \
    --enable-lapack2flame \
    --enable-dynamic-build \
    --enable-max-arg-list-hack \
    --disable-autodetect-f77-ldflags --disable-autodetect-f77-name-mangling \
    $extra_flags

make -j${nproc} BLAS_LIB="${LBT}"
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.8"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

products = [
    LibraryProduct("libflame", :libflame),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", clang_use_lld=false, lock_microarchitecture=false, julia_compat="1.6")
