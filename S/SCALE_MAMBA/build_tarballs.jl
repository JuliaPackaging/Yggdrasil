using BinaryBuilder

name = "SCALE_MAMBA"
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
products = [
    ExecutableProduct("Player.x", :playerx),
    ExecutableProduct("Setup.x", :setupx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "OpenSSL_jll",
    "MPIR_jll",
    "cryptopp_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
