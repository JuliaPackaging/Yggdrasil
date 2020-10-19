using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.10.5"

sources = [
    # Crib MacOS and Linux binaries from PyPI
    FileSource("https://files.pythonhosted.org/packages/2c/47/e0d58be6f292684a4541d10b1da953542ff679f3ffc6096bee73634832b1/h5py-2.10.0-cp27-cp27m-macosx_10_6_intel.whl", "ecf4d0b56ee394a0984de15bceeb97cbe1fe485f1ac205121293fc44dcf3f31f"),
    FileSource("https://files.pythonhosted.org/packages/3f/b6/23155e343f8719923449ccfebac296c1ab0dda9bdccc28242e1594469f5a/h5py-2.10.0-cp27-cp27m-manylinux1_i686.whl", "86868dc07b9cc8cb7627372a2e6636cdc7a53b7e2854ad020c9e9d8a4d3fd0f5"),
    FileSource("https://files.pythonhosted.org/packages/3a/9b/5b68a27110d459704550cfc0c765a1ae6ee98981cbbbf0ca92983c87046a/h5py-2.10.0-cp27-cp27m-manylinux1_x86_64.whl", "aac4b57097ac29089f179bbc2a6e14102dd210618e94d77ee4831c65f82f17c0"),

    # Take advantage of msys2 mingw builds of HDF5 for Windows
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-hdf5-1.10.5-1-any.pkg.tar.xz", "d29a56297219e1981f393e266ee515605237323fc20b0a69a45961c4bfe5e9da"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-szip-2.1.1-2-any.pkg.tar.xz", "58b5efe1420a2bfd6e92cf94112d29b03ec588f54f4a995a1b26034076f0d369"),
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-zlib-1.2.11-7-any.pkg.tar.xz", "addf6c52134027407640f1cbdf4efc5b64430f3a286cb4e4c4f5dbb44ce55a42"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-szip-2.1.1-2-any.pkg.tar.xz", "ec8fe26370b0673c4b91f5ccf3404907dc7c24cb9d75c7b8830aa93a7c13ace7"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-hdf5-1.10.5-1-any.pkg.tar.xz", "e01196dd53711304aa4026932c153171606efc4d6938dd3c172b6b40d9e7cdd9"),
    ArchiveSource("http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-zlib-1.2.11-7-any.pkg.tar.xz", "1decf05b8ae6ab10ddc9035929014837c18dd76da825329023da835aec53cec2"),

     # We need some special compiler support libraries from mingw
    ArchiveSource("http://repo.msys2.org/mingw/i686/mingw-w64-i686-gcc-libs-9.1.0-3-any.pkg.tar.xz", "416819d44528e856fb1f142b41fd3b201615d19ddaed8faa5d71296676d6fa17"),

    # Native build for arm
    ArchiveSource("https://github.com/JuliaPackaging/Yggdrasil/releases/download/HDF5-arm-linux-gnueabihf-v1.10.5/hdf5-arm-linux-gnueabihf-v1.10.5.tar.gz", "12797e8f8b864dd1a5846c09a3efa21439844f76507483b373690b22bc2f09d7"),

    # Conda build (no MPI) for aarch64
    ArchiveSource("https://anaconda.org/conda-forge/hdf5/1.10.5/download/linux-aarch64/hdf5-1.10.5-nompi_h3c11f04_1104.tar.bz2", "46300770bb662aaefc92a9e21c5f78ebfaac5c00d4963844c3f730836400edb2";
                  unpack_target = "hdf5-aarch64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${prefix}/lib ${prefix}/bin

# If we're on Windows, extract from msys2 builds.  Otherwise, extract from .whl files
if [[ ${target} == x86_64-*mingw* ]]; then
    mv mingw64/bin/*.dll ${prefix}/bin
elif [[ ${target} == i686-*mingw* ]]; then
    mv mingw32/bin/*.dll ${prefix}/bin
elif [[ "${target}" == arm-linux-gnueabihf ]]; then
    cd hdf5-arm-linux-gnueabihf-*
    # Remove zlib headers that shouldn't be here
    rm include/z*.h
    for dir in bin include lib share; do
        mkdir -p "${prefix}/${dir}"
        cp -r ${dir}/* "${prefix}/${dir}"
    done
    chmod 755 ${bindir}/*
elif [[ "${target}" == aarch64-* ]]; then
    cd hdf5-aarch64-linux-gnu/
    for dir in bin include lib info; do
        mkdir -p "${prefix}/${dir}"
        cp -r ${dir}/* "${prefix}/${dir}"
    done
    chmod 755 ${bindir}/*
else
    if [[ ${target} == x86_64-linux-gnu ]]; then
        WHL_FILE="*h5py-*manylinux1_x86_64*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == i686-linux-gnu ]]; then
        WHL_FILE="*h5py-*manylinux1_i686*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == x86_64-apple-darwin* ]]; then
        WHL_FILE="*h5py-*macosx*.whl"
        LIBSDIR=.dylibs
    else
        echo "ERROR: Unsupported platform ${target}" >&2
        exit 1
    fi

    unzip "${WHL_FILE}"

    mv h5py/${LIBSDIR}/lib{sz,aec,hdf5}* ${prefix}/lib
fi

# We want libhdf5 to use OUR libz, so we force it to:
if [[ ${target} == *86*linux* ]]; then
    # We want libhdf5 to use OUR libz, so we force it to:
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        patchelf --replace-needed $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.${dlext}.1 ${f}
    done
elif [[ ${target} == *apple* ]]; then
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        install_name_tool -change $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.1.${dlext} ${f}
    done
fi

# We need to be able to access `libhdf5` and `libhdf5_hl` directly, so symlink it from the hashed filename from manylinux pypi
if [[ ${target} == *86*linux* ]]; then
    libhdf5name=$(basename ${prefix}/lib/libhdf5-*.${dlext}*)
    base="${libhdf5name%%.*}"
    ext="${libhdf5name#$base}"
    ln -s ${libhdf5name} ${prefix}/lib/libhdf5${ext}

    libhdf5_hlname=$(basename ${prefix}/lib/libhdf5_hl-*.${dlext}*)
    base="${libhdf5_hlname%%.*}"
    ext="${libhdf5_hlname#$base}"
    ln -s ${libhdf5_hlname} ${prefix}/lib/libhdf5_hl${ext}
fi

if [[ "${target}" != arm-linux-gnueabihf ]] && [[ "${target}" != aarch64-linux-gnueabihf ]]; then
    # Install headers
    mkdir -p "${prefix}/include"
    if [[ "${target}" == *-mingw* ]]; then
        # Use MinGW header files, which of course are different
        # from those for the other operating systems.
        cp -r mingw${nbits}/include/* "${prefix}/include"
    else
        # Use headers from the ARM build, with the hope that they'll be fine
        cp ${WORKSPACE}/srcdir/hdf5-arm-linux-gnueabihf-*/include/* "${prefix}/include"
    fi
fi
install_license ${WORKSPACE}/srcdir/hdf5-arm-linux-gnueabihf-*/share/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("armv7l", "linux"; libc="glibc"),
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
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
