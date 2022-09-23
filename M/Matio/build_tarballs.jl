# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Matio"
version = v"1.5.23"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tbeu/matio", "e9e063e08ef2a27fcc22b1e526258fea5a5de329")
]

# Bash recipe for building across all platforms
script = raw"""

cd matio

# trying with cmake


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
        -DHDF5_DIR:PATH=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
	    # -DZLIB_INCLUDE_DIR:PATH=${prefix}/include \
        # -DZLIB_LIBRARY:FILEPATH=${prefix}/lib/libz.${LD_EXT}

cmake --build .
cmake --install .

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libmatio", :libmatio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("HDF5_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
