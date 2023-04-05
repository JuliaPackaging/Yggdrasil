using BinaryBuilder

name = "SCALE_MAMBA"
version = v"1.5"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/KULeuven-COSIC/SCALE-MAMBA.git",
              "d7c960afd0a9776f04e15a5653caf300dd42f20a"),
    DirectorySource("./bundled"),
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
install -Dvm 755 "Player.x${exe}" "${bindir}/Player.x${exe}"
install -Dvm 755 "Setup.x${exe}" "${bindir}/Setup.x${exe}"
"""

# Only x86_64, no FreeBSD or windows, and no musl
platforms = [p for p in supported_platforms() if arch(p) == "x86_64" && !Sys.isfreebsd(p) && !Sys.iswindows(p) && libc(p) != "musl"]

# The products that we will ensure are always built
products = [
    ExecutableProduct("Player.x", :playerx),
    ExecutableProduct("Setup.x", :setupx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("MPIR_jll"),
    Dependency("cryptopp_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Build with GCC 6 at least, to dodge C++ problems
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
