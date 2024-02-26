using BinaryBuilder, Pkg

name = "blasfeo"
version = v"0.1.3"

# Source
sources = [
    GitSource(
        "https://github.com/giaf/blasfeo.git",
        "386e6556ce643e9863458c2479192de4c9689b81",  # current master branch
    ),
]

# Build instructions
# NOTE:
#  This builds the library for the GENERIC target
#  In the future it'd be nice to specialize the TARGET flag to the build target
#  Sorta blocked by unclear mapping, and lack of specific options (like aarch64 apple) 
#    in the CMake interface in blasfeo
script = raw"""
cd $WORKSPACE/srcdir/blasfeo
mkdir build
cd build/
cmake \
    -D TARGET=GENERIC \
    -D MF=PANELMAJ \
    -D LA=HIGH_PERFORMANCE \
    -D CMAKE_INSTALL_PREFIX=${prefix} \
    -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -D CMAKE_BUILD_TYPE=Release \
    -D BUILD_SHARED_LIBS=ON \
    ..

echo "Finished cmake config"
if [[ "${target}" == *-linux-* ]]; then 
    echo "System is Linux"
    cmake -D CMAKE_C_FLAGS="-lrt" ..
fi
echo "Finished first conditional"
if [[ "${target}" == *-apple-* ]]; then 
    echo "Setting RPATH"
    cmake -D CMAKE_MACOSX_RPATH=1 ..
fi

cmake --build . --target install -j${nproc}
"""


# Platforms
platforms = supported_platforms(exclude=Sys.iswindows)

# Products
products = [
    LibraryProduct("libblasfeo", :blasfeo)
]

# Dependencies
dependencies = Dependency[]

# Build the tarballs
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies,
    julia_compat = "1.6"
)
