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

# Remove explicitly setting march in Makefile
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/remove_arch.patch

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
fi

# Build executables
make -j${nproc} CC="${CXX}" -C src

# Install executables into ${prefix}
install -Dvm 755 "Player.x${exeext}" "${bindir}/Player.x${exeext}"
install -Dvm 755 "Setup.x${exeext}" "${bindir}/Setup.x${exeext}"
"""

# Only x86_64, no FreeBSD or windows, and no musl
platforms = [p for p in supported_platforms() if arch(p) == "x86_64" && Sys.islinux(p) && libc(p) != "musl"]
platforms = expand_microarchitectures(platforms, ["avx","avx2","avx512"])

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
