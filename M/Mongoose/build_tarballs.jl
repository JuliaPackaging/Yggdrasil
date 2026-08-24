# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mongoose"
version = v"7.21.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cesanta/mongoose.git", "b1c2ffe1a0aa13e3d94075b1a2c66b8b43ac9116"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mongoose
mkdir -p ${libdir}

atomic_patch -p1 ../patches/add-mg_conn_get_fn_data-helper.patch

FLAGS="-fPIC -O2 -shared \
  -DMG_TLS=MG_TLS_BUILTIN \
  -DMG_ENABLE_IPV6=1 \
  -DMG_IO_SIZE=32768 \
  -DMG_MAX_RECV_SIZE=10485760"

LIBS=""
if [[ "${target}" == *mingw* ]]; then
    LIBS="-lws2_32"
fi

cc ${FLAGS} mongoose.c -o ${libdir}/libmongoose.${dlext} ${LIBS}

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmongoose", :libmongoose)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
