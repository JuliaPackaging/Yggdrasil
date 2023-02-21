using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.14.0"

sources = [
    # 32-bit Windows from https://packages.msys2.org/package/mingw-w64-i686-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-hdf5-1.14.0-3-any.pkg.tar.zst",
                  "b7fd69d444a9d1f71335c53ab6bfd1449eed9023133758130a042ed3f2c4504a";
                  unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-zlib-1.2.13-3-any.pkg.tar.zst",
                  "ed62c6f77f9cce488aed15726349d5d4537689583caab46bace8d41173db48b7";
                  unpack_target="i686-w64-mingw32"),

    # We need some special compiler support libraries from mingw for i686 (libgcc_s_dw2)
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-gcc-libs-12.2.0-10-any.pkg.tar.zst",
                  "f181e46ff9dce67379c51aa5f39b1c8dd42617f184d13639f53d9768379bc2b8";
                  unpack_target="i686-w64-mingw32"),

    # 64-bit Windows from https://packages.msys2.org/package/mingw-w64-x86_64-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-hdf5-1.14.0-3-any.pkg.tar.zst",
                  "c4a889e09b43e0ec1f9a872acbfc62f34291ee935c26ea90ca9911104f9627d3";
                  unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-zlib-1.2.13-3-any.pkg.tar.zst",
                  "7fc6ac1629180e205f0fdbe7abd04353136a44d73d16924f0c64fd10828329a7";
                  unpack_target="x86_64-w64-mingw32"),

    # x86_64 and aarch64 for Linux and macOS from https://anaconda.org/conda-forge/hdf5/files
    # NOTE: make sure to select those compatible with OpenSSL 1.1.1 (click info icon)
    # Unfortunately we cannot use conda-forge HDF 1.12.2 binaries since their libcurl is too new for us.
    # The MinGW 1.12.1 binaries work for HDF5.jl but not with libnetcdf. To have a HDF5_jll version
    # that works on all platforms, we resort to mixing two different patch versions.
    # See discussion following https://github.com/JuliaPackaging/Yggdrasil/issues/4511#issuecomment-1198134988
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.14.0/download/linux-64/hdf5-1.14.0-nompi_h5231ba7_102.conda",
                  "d64e2e691205920a0d0f15876d4bcade18f98ef126959d21316a297516476c7c";
                  unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.14.0/download/linux-aarch64/hdf5-1.14.0-nompi_h4e7b029_102.conda",
                  "127b4b6a0323c504b197f1ee8e05f9857a57bd51331de15937c8a9cb7b3a302c";
                  unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.14.0/download/osx-64/hdf5-1.14.0-nompi_h058c35b_102.conda",
                  "60a1cf488de41fd7353a0775b749031c91a060ac6c957c93349f482179ed9a89";
                  unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.14.0/download/osx-arm64/hdf5-1.14.0-nompi_hc28a057_102.conda",
                  "1cb95014e706b832459784975947a958171ea9903aae077565f775d6f3154fad";
                  unpack_target="aarch64-apple-darwin20"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${libdir} ${includedir}

if [[ ${target} == *mingw* ]]; then
    cd ${target}/mingw${nbits}

    rm -f lib/{*_cpp*,*fortran*,*f90*} # we do not need these
    rm -f bin/{*_cpp*,*fortran*,*f90*} # we do not need these
    
    mv -v lib/libhdf5*.dll.a ${prefix}/lib
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
    Dependency("libaec_jll"; compat="1.0.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
