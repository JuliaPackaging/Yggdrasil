using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.12.2"

sources = [
    # 32-bit Windows from https://packages.msys2.org/package/mingw-w64-i686-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-hdf5-1.12.2-1-any.pkg.tar.zst", "f37511b6208245b081a5b72a1f2021a73b67da07835ede1e092f7d7f20569319"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-libaec-1.0.6-2-any.pkg.tar.zst", "c6cff1a6f8a9f75e986589d8debc35e8076a7af38aa32cbda78bb6c2fbbbe58c"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-zlib-1.2.12-1-any.pkg.tar.zst", "74ace327d8e28cdb0c777fffc6003f5097836c247be40cf3b483bd9fd1c23183"; unpack_target="i686-w64-mingw32"),
    # We need some special compiler support libraries from mingw for i686 (libgcc_s_dw2)
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-gcc-libs-12.1.0-3-any.pkg.tar.zst", "dbf02e2b0569677879597f404ed2c15bb1d2998c2d19412b1ac33afd104d9dbf"; unpack_target="i686-w64-mingw32"),

    # 64-bit Windows from https://packages.msys2.org/package/mingw-w64-x86_64-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-hdf5-1.12.2-1-any.pkg.tar.zst", "3ba6521d45368aabb334131e10282b25fab9891a20fb9129d897c65c8b6cdbda"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-libaec-1.0.6-2-any.pkg.tar.zst", "d970bd71e55fc5bd4a55e95ef22355d8c479631973860f2a9c37b49c931c5f35"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-zlib-1.2.12-1-any.pkg.tar.zst", "e728df08b4db7b291a52d8fd60b96f19016f059ab15170fc98120e5d580c86ac"; unpack_target="x86_64-w64-mingw32"),

    # x86_64 and aarch64 for Linux and macOS from https://anaconda.org/conda-forge/hdf5/files
    # NOTE: make sure to select those compatible with OpenSSL 1.1.1 (click 🛈)
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.2/download/linux-64/hdf5-1.12.2-nompi_h2386368_100.tar.bz2", "6f0a1e7fe9c76fee4f490b33a91465a3a4690a5ccf1df21c7bde141ab320ea96"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.2/download/linux-aarch64/hdf5-1.12.2-nompi_h7bde11e_100.tar.bz2", "934324fea28f82ceb0f57c881bf49687154c17af8cc7a1a57753133e5224db2c"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.2/download/osx-64/hdf5-1.12.2-nompi_hc782337_100.tar.bz2", "066c8feca3d77184e7cb38cd58d9918409f7395a66b16e7d330339225f9c0bea"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.2/download/osx-arm64/hdf5-1.12.2-nompi_h8968d4b_100.tar.bz2", "3efe747b24b173c6c3be71009c1831049032d81d0414d07d920b0650b8022a58"; unpack_target="aarch64-apple-darwin20"),
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

    # Delete the C++ and Fortran libraries, we can't use them because they'd restrict the
    # ABIs we can use this package for (e.g., *only* libgfortran5 and C++11 string ABI),
    # which would be overly restrictive, as Julia on Linux comes with libgfortran4, thus
    # making this package completely unusable there.  The only way to use the C++ and
    # Fortran libraries is for BinaryBuilder to be able to actually build them:
    # <https://github.com/JuliaPackaging/Yggdrasil/issues/4760>.
    rm -f lib/{*_cpp*,*_fortran*}
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
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
