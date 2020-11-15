using BinaryBuilder, Pkg

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.12.0"

sources = [
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.0/download/osx-64/hdf5-1.12.0-nompi_h2ccf146_102.tar.bz2", "f89ea2cbb84ea8b7e03f7e54c969ee94515a9ac069f2062ce2410d1797206cba", unpack_target = "x86_64-apple-darwin14"),

    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.0/download/linux-64/hdf5-1.12.0-nompi_h1022a3e_102.tar.bz2", "74dc7a85d52c4e6c339c03ca44ed5e4989fe506360abc7cc999d17c32ae96423", unpack_target = "x86_64-linux-gnu"),

    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-hdf5-1.12.0-2-any.pkg.tar.zst", "d9ade0d0fddfdeca3ea9de00b066e330e1573c547609a12b81c6a080b2c19f3e", unpack_target = "i686-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-szip-2.1.1-2-any.pkg.tar.xz", "58b5efe1420a2bfd6e92cf94112d29b03ec588f54f4a995a1b26034076f0d369", unpack_target = "i686-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-zlib-1.2.11-7-any.pkg.tar.xz", "addf6c52134027407640f1cbdf4efc5b64430f3a286cb4e4c4f5dbb44ce55a42", unpack_target = "i686-w64-mingw32"),
    # We need some special compiler support libraries from mingw for i686
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-gcc-libs-10.2.0-5-any.pkg.tar.zst", "e03a63b24695951a1e80def754d6bd128744eaf1e562308ded31e989636e7651", unpack_target = "i686-w64-mingw32"),

    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-hdf5-1.12.0-2-any.pkg.tar.zst", "549462ad99a079ff725ac4bd1f662d3594515320ea324a7263a647578b258d86", unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-szip-2.1.1-2-any.pkg.tar.xz", "ec8fe26370b0673c4b91f5ccf3404907dc7c24cb9d75c7b8830aa93a7c13ace7", unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-zlib-1.2.11-7-any.pkg.tar.xz", "1decf05b8ae6ab10ddc9035929014837c18dd76da825329023da835aec53cec2", unpack_target = "x86_64-w64-mingw32"),

    ## Native build for arm
    #ArchiveSource("https://github.com/JuliaPackaging/Yggdrasil/releases/download/HDF5-arm-linux-gnueabihf-v1.10.5/hdf5-arm-linux-gnueabihf-v1.10.5.tar.gz", "12797e8f8b864dd1a5846c09a3efa21439844f76507483b373690b22bc2f09d7"),

    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.0/download/linux-aarch64/hdf5-1.12.0-nompi_h1022a3e_102.tar.bz2", "605aff906fd0fca9a52da6ad9b48607fab5cb26e2615d3827a1f318d6e103c4a", unpack_target = "aarch64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/

if [[ ${target} == *-mingw32 ]]; then
    cd ${target}/mingw${nbits}

    rm -f bin/{*_cpp*,*fortran*,*f90*} # we do not need these
    cp -r bin/*.{dll,exe} ${libdir}
    cp -r include/* ${includedir}

    install_license ${WORKSPACE}/srcdir/${target}/mingw${nbits}/share/doc/hdf5/COPYING
elif [[ ${target} == aarch64-* || ${target} == x86_64-linux-gnu || ${target} == x86_64-apple-darwin* ]]; then
    cd ${target}

    rm -f lib/{*_cpp*,*_fortran*} # we do not need these
    cp -r bin/* ${bindir}
    cp -r lib/*  ${libdir}
    cp -r include/* ${includedir}

    chmod +x ${bindir}/*

    install_license ${WORKSPACE}/srcdir/${target}/info/licenses/COPYING
else
    echo "ERROR: Unsupported platform ${target}" >&2
    exit 1
fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    # Platform("i686", "linux"),
    # Platform("armv7l", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
# platforms = expand_cxxstring_abis(platforms)
# platforms = expand_gfortran_versions(platforms)

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
    # Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
