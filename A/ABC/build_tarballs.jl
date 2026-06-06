using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# abc
name = "ABC"
version = v"1.01.2"
upstream_version = "1.01.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/berkeley-abc/abc.git",
        "f4d870e109938fd1a283ecceea950bd9cd616f67"
    )
]

script = raw"""
cd ${WORKSPACE}/srcdir/abc

install -Dv abc.rc ${prefix}/abc.rc

# select compiler based on target platform
# ABC on Apple platforms can be compiled using clang instead of gcc,
# while clang fails on Linux
if [[ "${target}" == *-apple-* ]]; then
    CC=clang
    CXX=clang++
else
    CC=gcc
    CXX=g++
fi

EXFLGS="\
-fPIC \
-Wall \
-Wno-unused-function \
-Wno-write-strings \
-Wno-sign-compare \
-Wno-unused-but-set-variable \
-DSIZEOF_INT=4 \
-DABC_USE_CUDD=1 \
-DABC_USE_PTHREADS \
-DABC_USE_STDINT_H=1 \
-DSIZEOF_VOID_P=8 \
-DSIZEOF_LONG=8 \
"

# make libabc.so
make -j${nproc} CC=${CC} CXX=${CXX} CFLAGS+="${EXFLGS}" libabc.so
# the abc Makefile always makes a .so  Fix that here.
install -Dvm 755 "libabc.so" "${libdir}/libabc.${dlext}"

make -j${nproc} CC=${CC} CXX=${CXX} CFLAGS+="${EXFLGS}"
mkdir -p "${bindir}"
cp abc${exeext} ${bindir}
chmod +x ${bindir}/*
install_license copyright.txt
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# core-math uses unsigned __int128 which is unavailable on 32-bit platforms
platforms = supported_platforms(exclude= x -> (
    Sys.iswindows(x) ||
    Sys.isfreebsd(x) ||
    nbits(x) == 32
))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("abc", :abc),
    LibraryProduct("libabc", :libabc),
    FileProduct("abc.rc", :abc_rc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Readline_jll"),
    Dependency(PackageSpec(
        name="CompilerSupportLibraries_jll",
        uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"
    ))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script,
    platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"8",
    preferred_llvm_version=v"13",
    clang_use_lld=false,
)
