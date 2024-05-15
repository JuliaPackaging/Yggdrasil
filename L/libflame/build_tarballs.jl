name = "libflame"

using BinaryBuilder, Pkg

version = v"5.2.0"

# Collection of sources required to build lapack
sources = [
    GitSource("https://github.com/flame/libflame",
              "646ed9075cc45aeffb53632a3ec88defb423fefa"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all 64-bit platforms
# We try to maintain consistency with the blis Yggdrasil build scripts.

script = raw"""
cd $WORKSPACE/srcdir/libflame

# We might need newer `config.guess`` and `config.sub` files
update_configure_scripts

# disable time & clock functions on windows (mingw): sys/times.h is missing
if [[ "${target}" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows-remove-time.patch
fi

# - Compile and build a LAPACK compatibility layer with --enable-lapack2flame
# - If a static library is not needed, use --disable-static-build
# - Enable a dynamic build with --enable-dynamic-build
./configure \
--prefix=${prefix} --build=${MACHTYPE} --host=${target} \
--enable-multithreading=openmp \
--enable-lapack2flame \
--enable-dynamic-build \
--enable-cblas-interfaces \
--disable-autodetect-f77-ldflags --disable-autodetect-f77-name-mangling

make -j${nproc}
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
    # Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),
]

# Enable the following line if trying to link against Fortran code:
# platforms = expand_gfortran_versions(platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    RuntimeDependency(PackageSpec(name="blis_jll", uuid="6136c539-28a5-5bf0-87cc-b183200dce32")),
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
               preferred_gcc_version=v"11", lock_microarchitecture=false, julia_compat="1.6")
