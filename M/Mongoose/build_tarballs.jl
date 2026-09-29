# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mongoose"
version = v"7.23.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cesanta/mongoose.git", "02bdbb9ed6f0a8f7c42228c6e7cb35d748b60551"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mongoose
mkdir -p ${libdir}

cp ../mg_conn_get_fn_data.c .

FLAGS="-fPIC -O2 -shared \
  -DMG_TLS=MG_TLS_BUILTIN \
  -DMG_ENABLE_IPV6=1 \
  -DMG_IO_SIZE=32768 \
  -DMG_MAX_RECV_SIZE=10485760"

LIBS=""
if [[ "${target}" == *mingw* ]]; then
    LIBS="-lws2_32"
fi

${CC} ${FLAGS} mongoose.c mg_conn_get_fn_data.c -o ${libdir}/libmongoose.${dlext} ${LIBS}

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
