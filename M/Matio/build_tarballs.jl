# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Matio"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tbeu/matio", "e9e063e08ef2a27fcc22b1e526258fea5a5de329")
]

# Bash recipe for building across all platforms
script = raw"""

cd matio
git submodule update --init

# trying with cmake

OS=$(uname -s)
if [ "$OS" = "Darwin" ] ; then
    LD_EXT="dylib"
else
    LD_EXT="so"
fi

cmake . -DCMAKE_C_COMPILER:FILEPATH=${CC} \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DMATIO_SHARED:BOOL=ON \
	    -DMATIO_DEFAULT_FILE_VERSION=7.3 \
        -DMATIO_MAT73:BOOL=ON \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_INSTALL_LIBDIR:PATH=lib \
        -DMATIO_WITH_HDF5:BOOL=ON \
        -DMATIO_WITH_ZLIB:BOOL=ON \
        -DHDF5_ROOT:PATH=${prefix} \
        -DHDF5_DIR:PATH=${prefix}
	    # -DZLIB_INCLUDE_DIR:PATH=${prefix}/include 
        # -DZLIB_LIBRARY:FILEPATH=${prefix}/lib/libz.${LD_EXT}

cmake --build .
cmake --install .
# if [ "$OS" == "Darwin" ] ; then
#     echo "Installing libtool"
#     brew install libtool
# fi

# ./autogen.sh
# ./configure --with-zlib=${prefix} --with-hdf5=${prefix} --prefix=${prefix} --enable-mat73 --enable-shared
# make
# make check
# make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macOs"),
    Platform("aarch64", "macOs"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmatio", :libmatio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("HDF5_jll", compat="1.12.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
