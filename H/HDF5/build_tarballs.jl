using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.12.0"

sources = [
    FileSource("https://files.pythonhosted.org/packages/d5/f9/676c6a5c13806289da6177c538ce772e3e5b04ea10d76e6e72e9f0d042de/h5py-3.1.0-cp39-cp39-macosx_10_9_x86_64.whl", "cb74df83709d6d03d11e60b9480812f58da34f194beafa8c8314dbbeeedfe0a6"),

    FileSource("https://files.pythonhosted.org/packages/40/1b/dd36e8aa1b7c9d82a1f0aaabece4393797ded0ff613437dfb8c0780b33a9/h5py-3.1.0-cp39-cp39-manylinux1_x86_64.whl", "80c623be10479e81b64fa713b7ed4c0bbe9f02e8e7d2a2e5382336087b615ce4"),

    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-hdf5-1.12.0-2-any.pkg.tar.zst", "d9ade0d0fddfdeca3ea9de00b066e330e1573c547609a12b81c6a080b2c19f3e", unpack_target = "i686-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-szip-2.1.1-2-any.pkg.tar.xz", "58b5efe1420a2bfd6e92cf94112d29b03ec588f54f4a995a1b26034076f0d369", unpack_target = "i686-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-zlib-1.2.11-7-any.pkg.tar.xz", "addf6c52134027407640f1cbdf4efc5b64430f3a286cb4e4c4f5dbb44ce55a42", unpack_target = "i686-w64-mingw32"),
    # We need some special compiler support libraries from mingw for i686
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-gcc-libs-10.2.0-5-any.pkg.tar.zst", "e03a63b24695951a1e80def754d6bd128744eaf1e562308ded31e989636e7651", unpack_target = "i686-w64-mingw32"),

    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-hdf5-1.12.0-2-any.pkg.tar.zst", "549462ad99a079ff725ac4bd1f662d3594515320ea324a7263a647578b258d86", unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-szip-2.1.1-2-any.pkg.tar.xz", "ec8fe26370b0673c4b91f5ccf3404907dc7c24cb9d75c7b8830aa93a7c13ace7", unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-zlib-1.2.11-7-any.pkg.tar.xz", "1decf05b8ae6ab10ddc9035929014837c18dd76da825329023da835aec53cec2", unpack_target = "x86_64-w64-mingw32"),

    # Can't use conda-forge on other platforms since it links too many libraries, but apparently on aarch64 is fine
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.12.0/download/linux-aarch64/hdf5-1.12.0-nompi_h1022a3e_102.tar.bz2", "605aff906fd0fca9a52da6ad9b48607fab5cb26e2615d3827a1f318d6e103c4a", unpack_target = "aarch64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${libdir} ${includedir}

if [[ ${target} == *mingw* ]]; then
    cd ${target}/mingw${nbits}

    rm -f bin/{*_cpp*,*fortran*,*f90*} # we do not need these
    mv bin/*.dll ${libdir}
    mv include/* ${includedir}

    install_license share/doc/hdf5/COPYING
elif [[ ${target} == aarch64-* ]]; then
    cd ${target}

    rm -f lib/{*_cpp*,*_fortran*} # we do not need these
    mv lib/* ${libdir}
    mv include/* ${includedir}

    install_license info/licenses/COPYING
else
    if [[ ${target} == x86_64-linux-gnu ]]; then
        WHL_FILE="*h5py-*manylinux1_x86_64*.whl"
        LIBSDIR=h5py.libs
    elif [[ ${target} == x86_64-apple-darwin* ]]; then
        WHL_FILE="*h5py-*macosx*.whl"
        LIBSDIR=h5py/.dylibs
    else
        echo "ERROR: Unsupported platform ${target}" >&2
        exit 1
    fi

    unzip ${WHL_FILE}
    mv ${LIBSDIR}/* ${libdir}

    # Use headers and license from aarch64-linux-gnu with the hope that they'll be fine
    mv aarch64-*/include/* ${includedir}
    install_license aarch64-*/info/licenses/COPYING
fi

# We need to be able to access `libhdf5` and `libhdf5_hl` directly, so symlink it from the hashed filename from manylinux pypi
if [[ ${target} == *86*linux* ]]; then
    libhdf5name=$(basename ${libdir}/libhdf5-*.${dlext}*)
    base="${libhdf5name%%.*}"
    ext="${libhdf5name#$base}"
    ln -s ${libhdf5name} ${libdir}/libhdf5${ext}
    libhdf5_hlname=$(basename ${libdir}/libhdf5_hl-*.${dlext}*)
    base="${libhdf5_hlname%%.*}"
    ext="${libhdf5_hlname#$base}"
    ln -s ${libhdf5_hlname} ${libdir}/libhdf5_hl${ext}
fi

if [[ ! ${target} == *-mingw* ]]; then
    if [[ ! -f ${libdir}/libhdf5${dlext} ]]; then
        ln -s ${libdir}/libhdf5.*${dlext} ${libdir}/libhdf5${dlext}
    fi

    if [[ ! -f ${libdir}/libhdf5_hl${dlext} ]]; then
        ln -s ${libdir}/libhdf5_hl.*${dlext} ${libdir}/libhdf5_hl${dlext}
    fi
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
