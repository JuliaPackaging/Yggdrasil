
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "casacore"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/casacore/casacore.git", "a735bf5f31ea012ac4f7f7378a1f89c1fc136a06"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/casacore

# Apply upstream patch that fixes i386 builds
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-Fix-compilation-of-RefTable-on-i386-platform-1129.patch

# Apply strerror patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0002-Use-overloading-to-detect-strerror-variant.patch

mkdir build && cd build
CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

# Disable OpenMP, it'll probably interfere with Julia's threads
CMAKE_FLAGS+=(-DUSE_OPENMP=OFF)

# Don't build python hooks
CMAKE_FLAGS+=(-DBUILD_PYTHON=no)

# Stock FFTW3 has threads already baked in
CMAKE_FLAGS+=(-DFFTW3_DISABLE_THREADS=yes)

# linux builds need to link against rt (they don't do this for some reason)
if [[ ${target} == *-linux-* ]]; then
    CMAKE_FLAGS+=(-DCASACORE_ARCH_LIBS="-lrt")
fi

# Congire
cmake ${CMAKE_FLAGS[@]} ..

# Make and install
make -j${nproc}
make install
exit
"""

# Exclude windows, casacore needs pread and pwrite, which are POSIX-only
# Also exclude FreeBSD, lots of upstream bugs that seem not worth fixing ourself
platforms = supported_platforms(experimental=true, exclude=(platform)-> Sys.iswindows(platform) || Sys.isfreebsd(platform))
# Deal with the fact that we have std::string values, which causes issues across the gcc 4/5 boundary
platforms = expand_cxxstring_abis(platforms)
# expand gfortran versions as well
platforms = expand_gfortran_versions(platforms)
# Exclude all musl builds, upstream doesn't care and they use a few glibc-specific features
filter!(p -> libc(p) != "musl", platforms)
# Exclude powerpc64le-linux-gnu-libgfortran3, something is very wonky with that particular combination
# Is it worth fixing?
filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libcasa_casa", :libcasa_casa),
    LibraryProduct("libcasa_coordinates", :libcasa_coordinates),
    LibraryProduct("libcasa_derivedmscal", :libcasa_derivedmscal),
    LibraryProduct("libcasa_fits", :libcasa_fits),
    LibraryProduct("libcasa_images", :libcasa_images),
    LibraryProduct("libcasa_lattices", :libcasa_lattices),
    LibraryProduct("libcasa_meas", :libcasa_meas),
    LibraryProduct("libcasa_measures", :libcasa_measures),
    LibraryProduct("libcasa_mirlib", :libcasa_mirlib),
    LibraryProduct("libcasa_msfits", :libcasa_msfits),
    LibraryProduct("libcasa_ms", :libcasa_ms),
    LibraryProduct("libcasa_scimath_f", :libcasa_scimath_f),
    LibraryProduct("libcasa_scimath", :libcasa_scimath),
    LibraryProduct("libcasa_tables", :libcasa_tables),
    ExecutableProduct("findmeastable", :findmeastable),
    ExecutableProduct("fits2table", :fits2table),
    ExecutableProduct("image2fits", :image2fits),
    ExecutableProduct("imagecalc", :imagecalc),
    ExecutableProduct("imageregrid", :imageregrid),
    ExecutableProduct("imageslice", :imageslice),
    ExecutableProduct("lsmf", :lsmf),
    ExecutableProduct("measuresdata", :measuresdata),
    ExecutableProduct("measuresdata-update", :measuresdata_update),
    ExecutableProduct("ms2uvfits", :ms2uvfits),
    ExecutableProduct("msselect", :msselect),
    ExecutableProduct("readms", :readms),
    ExecutableProduct("showtableinfo", :showtableinfo),
    ExecutableProduct("showtablelock", :showtablelock),
    ExecutableProduct("tablefromascii", :tablefromascii),
    ExecutableProduct("taql", :taql),
    ExecutableProduct("tomf", :tomf),
    ExecutableProduct("writems", :writems),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="CFITSIO_jll", uuid="b3e40c51-02ae-5482-8a39-3ace5868dcf4"))
    Dependency(PackageSpec(name="WCS_jll", uuid="550c8279-ae0e-5d1b-948f-937f2608a23e"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7", preferred_gcc_version = v"5.2")
