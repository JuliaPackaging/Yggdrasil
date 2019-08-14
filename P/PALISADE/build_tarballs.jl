using BinaryBuilder

# Collection of sources required to build Nettle
name = "PALISADE"
version = v"1.4.1"
sources = [
    "https://git.njit.edu/palisade/PALISADE/-/archive/PALISADE-v1.4.1/PALISADE-PALISADE-v1.4.1.tar.gz" =>
    "cdeddfc6d6f059047d626ff0e221b3455058bd5bcabdef8602ba53b5586e3377",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PALISADE*

# We need coreutils
apk add coreutils

# Don't build GMP, we've already got it
mkdir -p third-party/lib
touch third-party/lib/lib{gmp,ntl}.a

export CFLAGS="${CFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib"

FLAGS=(PREFIX="${prefix}" GMP_UNPACK_NEEDED= NTL_UNPACK_NEEDED= THIRDPARTYINCLUDE="-I${prefix}/include -I$(pwd)/third-party/include -I$(pwd)/third-party/include/rapidjson" NTLLIB=${prefix}/lib/libntl.so GMPLIB=${prefix}/lib/libgmp.so CXX="ccache ${CXX}")

make -j${nproc} "${FLAGS[@]}"
make installcore installpke installabe installsignature "${FLAGS[@]}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; compiler_abi=CompilerABI(:gcc6)),
    Linux(:x86_64; libc=:musl, compiler_abi=CompilerABI(:gcc6)),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libsnark", :libsnark),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/ntl-v10.5.0%2B0/build_ntl.v10.5.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
