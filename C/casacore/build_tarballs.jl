
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "casacore"
version = v"3.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/casacore/casacore.git", "67b7d63dc333c5d4fce5d92f125c1e0ce0e3514a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/casacore

apk del cmake

mkdir build && cd build
CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Set the toolchain
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Disable OpenMP, it'll probably interfere with Julia's threads
CMAKE_FLAGS+=(-DUSE_OPENMP=OFF)

# Don't build python hooks
CMAKE_FLAGS+=(-DBUILD_PYTHON3=OFF)

# Build "portable" code
CMAKE_FLAGS+=(-DPORTABLE=ON)

# Stock FFTW3 has threads already baked in
CMAKE_FLAGS+=(-DFFTW3_DISABLE_THREADS=yes)

# linux builds need to link against rt (they don't do this for some reason)
if [[ ${target} == *-linux-* ]]; then
    CMAKE_FLAGS+=(-DCASACORE_ARCH_LIBS="-lrt")
fi

# Explicitly link BLAS to LBT
CMAKE_FLAGS+=(-DBLA_VENDOR="libblastrampoline")

# Configure
${host_bindir}/cmake ${CMAKE_FLAGS[@]} ..

# Make and install
make -j${nproc}
make install
exit
"""

# Exclude windows, casacore needs pread and pwrite, which are POSIX-only
# Also exclude FreeBSD, lots of upstream bugs that seem not worth fixing ourself
platforms = supported_platforms(exclude=(platform) -> Sys.iswindows(platform) || Sys.isfreebsd(platform) || arch(platform) == "riscv64")
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
    HostBuildDependency(PackageSpec(; name="CMake_jll")) # For a version of CMake where Find_BLAS can find LBT
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"); compat="3.3.10");
    Dependency(PackageSpec(name="CFITSIO_jll", uuid="b3e40c51-02ae-5482-8a39-3ace5868dcf4"); compat="4.4.0");
    Dependency(PackageSpec(name="WCS_jll", uuid="550c8279-ae0e-5d1b-948f-937f2608a23e"); compat="7.7.0");
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"));
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2");
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4");
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"));
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"));
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_gcc_version=v"8")
