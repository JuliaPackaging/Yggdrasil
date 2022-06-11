
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "casacore"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/casacore/casacore.git", "a735bf5f31ea012ac4f7f7378a1f89c1fc136a06")
]

# Bash recipe for building across all platforms
script = raw"""
OPENBLAS=(-lopenblas64_)

cd $WORKSPACE/srcdir/casacore

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_PYTHON=no \
      -DBLAS_LIBRARIES="${OPENBLAS[*]}" \
      -DFFTW3_DISABLE_THREADS=yes \
      ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# expand gfortran versions as well
platforms = expand_gfortran_versions(platforms)

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
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="CFITSIO_jll", uuid="b3e40c51-02ae-5482-8a39-3ace5868dcf4"))
    Dependency(PackageSpec(name="WCS_jll", uuid="550c8279-ae0e-5d1b-948f-937f2608a23e"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
