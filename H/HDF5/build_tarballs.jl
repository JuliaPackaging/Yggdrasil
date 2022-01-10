using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.12.1"

sources = [
    # 32-bit Windows from https://packages.msys2.org/package/mingw-w64-i686-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-hdf5-1.12.1-2-any.pkg.tar.zst", "ab7e4568c99e2a7a9b96ad06867ef9e829d286539e0735a93b9295ad8778a818"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-libaec-1.0.6-1-any.pkg.tar.zst", "43ef1aee2be7cc192d14c6641627ed0a1eca50c21234eba3405fce77302517a8"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-zlib-1.2.11-9-any.pkg.tar.zst", "8d594fc14497d41a66415bfdd200d7d1d56a6ecd3fe81b9190bec0c4841a5eff"; unpack_target="i686-w64-mingw32"),
    # We need some special compiler support libraries from mingw for i686
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-gcc-libs-11.2.0-6-any.pkg.tar.zst", "bdc359047f61c8e96401ba25b17c80f5f8039c25a063c622e3680123bb0de9d1"; unpack_target="i686-w64-mingw32"),

    # 64-bit Windows from https://packages.msys2.org/package/mingw-w64-x86_64-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-hdf5-1.12.1-2-any.pkg.tar.zst", "540d8b9fd71d0d848e28723f531948dea497c7cb8f95c53e1a3b06f750f12c40"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-libaec-1.0.6-1-any.pkg.tar.zst", "839b271b1313f013227c13944876651429b8e0edb40760d64f817a36c8b9435c"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-zlib-1.2.11-9-any.pkg.tar.zst", "9da9ebafaef832dba2f442ad44d9ae8759784b86478dcbe326500195f8ea6339"; unpack_target="x86_64-w64-mingw32"),

    # x86_64 and aarch64 for Linux and macOS from https://anaconda.org/conda-forge/hdf5/files
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.1/download/linux-64/hdf5-1.12.1-nompi_h7f166f4_103.tar.bz2", "a17c23e1c0992e7af96245da4d122dea09a16cb880af0bc6bdd768e561c1ae75"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.1/download/linux-aarch64/hdf5-1.12.1-nompi_he09bf5b_103.tar.bz2", "b5a923cf26b76b341e09c194a638e4840ffa5e99a67a99d1a8836554e094cec6"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.1/download/osx-64/hdf5-1.12.1-nompi_h2f0ef1a_103.tar.bz2", "d628295cc8d8358dbfbe1037b31f2e181efc06f008ae6711da409413a3cb5695"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.1/download/osx-arm64/hdf5-1.12.1-nompi_had0e5e0_103.tar.bz2", "ef48b684b22c6b0077bc9836e0cc6d15abb88868d7a6c842226666ebb8bbd449"; unpack_target="aarch64-apple-darwin20"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${libdir} ${includedir}

if [[ ${target} == *mingw* ]]; then
    cd ${target}/mingw${nbits}

    rm -f bin/{*_cpp*,*fortran*,*f90*} # we do not need these
    mv -v bin/*.dll ${libdir}
    mv -v include/* ${includedir}

    install_license share/doc/hdf5/COPYING
else
    cd ${target}

    rm -f lib/{*_cpp*,*_fortran*} # we do not need these
    mv -v lib/* ${libdir}
    mv -v include/* ${includedir}

    install_license info/licenses/COPYING
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libhdf5", :libhdf5),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
