using BinaryBuilder

name = "SCALE-MAMBA"
version = v"1.5"

# Collection of sources required to build SuiteSparse
sources = [
    "https://github.com/KULeuven-COSIC/SCALE-MAMBA.git" =>
    "d7c960afd0a9776f04e15a5653caf300dd42f20a",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/SCALE-MAMBA/

# Apply patch to fix multiple definitions error
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_multiple_definitions.patch

cat > CONFIG.mine <<EOF
ROOT = $(pwd)
OSSL = ${prefix}

# Take default values from typical CONFIG
MAX_MOD = 7
FLAGS = -DMAX_MOD_SZ=\$(MAX_MOD)
OPT = -O3
EOF

if [[ ${target} == *linux* ]]; then
    echo "LDFLAGS = -lrt" >> CONFIG.mine
fi

# Build executables
make -j${nproc} CC="${CXX}" -C src

# Install executables into ${prefix}
mkdir -p ${prefix}/bin
cp Player.x${exe} ${prefix}/bin/
cp Setup.x${exe} ${prefix}/bin/
"""

# Only x86_64, no FreeBSD or windows, and no musl
platforms = [p for p in supported_platforms() if arch(p) == :x86_64 && !isa(p, FreeBSD) && !isa(p, Windows) && libc(p) != :musl]

# Build with GCC 6 at least, to dodge C++ problems
platforms = BinaryBuilder.replace_gcc_version.(platforms, :gcc6)

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "Player.x", :playerx),
    ExecutableProduct(prefix, "Setup.x", :setupx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenSSL-v1.1.1%2Bc%2B0/build_OpenSSL.v1.1.1+c.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MPIR-v3.0.0%2B0/build_MPIR.v3.0.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/cryptopp-v8.2.0%2B1/build_cryptopp.v8.2.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
