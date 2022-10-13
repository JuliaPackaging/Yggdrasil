using BinaryBuilder

name = "SCALE_MAMBA"
version = v"1.14"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/KULeuven-COSIC/SCALE-MAMBA.git",
              "6449e807c99c68203f6584166a7130055da52adb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/SCALE-MAMBA/

# Resolve error: 'BinaryBuilder: Cannot force an architecture via -march'
atomic_patch -p1 ../patches/drop-march.patch

cat > CONFIG.mine <<EOF
ROOT = $(pwd)
OSSL = ${prefix}

# Take default values from typical CONFIG
MAX_MOD = 7
MAX_GFP = 3
FLAGS = -DMAX_MOD_SZ=\$(MAX_MOD) -DMAX_GFP_SZ=\$(MAX_GFP)
OPT = -O3
EOF

if [[ ${target} == *linux* ]]; then
    echo "LDFLAGS = -lrt" >> CONFIG.mine
elif [[ ${target} == *apple* ]]; then
    # Resolve: error: redefinition of 'time_s' with a different type: 'struct timeval' vs 'struct timespec'
    export CFLAGS="-D_POSIX_C_SOURCE=200112L"
fi

# Build executables
make -j${nproc} CC="${CXX}" -C src

# Install executables into ${prefix}
mkdir -p ${prefix}/bin
cp Player.x${exe} ${prefix}/bin/
cp Setup.x${exe} ${prefix}/bin/
"""

# Only x86_64, no FreeBSD or windows, and no musl
platforms = [Platform("x86_64", "linux"), Platform("x86_64", "macos")]

# The products that we will ensure are always built
products = [
    ExecutableProduct("Player.x", :playerx),
    ExecutableProduct("Setup.x", :setupx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"),
    Dependency("MPIR_jll"; compat="3.0.1"),
    Dependency("cryptopp_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat = "1.6")
