# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibStdCxx"
version = v"12.1.0"

include("../../0_RootFS/gcc_sources.jl")

sources = Any[
    gcc_version_sources[version]...,
    DirectorySource("./bundled")
]

script = raw"""
if [[ ${bb_full_target} == *-sanitize* ]]; then
    cp -rL $prefix/lib/linux/* /opt/x86_64-linux-musl/lib/clang/13.0.1/lib/linux/
fi
atomic_patch -p1 -d gcc-*/ $WORKSPACE/srcdir/patches/gcc-12-libstdcxx-sanitizers.patch
atomic_patch -p1 -d gcc-*/ $WORKSPACE/srcdir/patches/gcc-12-clang-bug-inline.patch

mkdir -p $WORKSPACE/srcdir/gcc_build
cd $WORKSPACE/srcdir/gcc_build

$WORKSPACE/srcdir/gcc-*/libstdc++-v3/configure \
--prefix="${prefix}" \
--target="${COMPILER_TARGET}" \
--host="${MACHTYPE}" \
--build="${MACHTYPE}" \
--disable-multilib \
--disable-werror \
--enable-shared \
--enable-threads=posix \
--enable-tls \
--with-sysroot="${sysroot}" \
--program-prefix="${COMPILER_TARGET}-"

cat <<-EOF >> config.h
#undef _GLIBCXX_USE_C99_FENV_TR1
#undef _GLIBCXX_X86_RDSEED
#undef _GLIBCXX_X86_RDRAND
#undef HAVE_ALIGNED_ALLOC
#define _GLIBCXX_HAS_GTHREADS 1
#define HAVE_CC_TLS 1 
#define HAVE_TLS 1
EOF

## Build, build, build!
make -j ${nproc}
make install

install_license /usr/share/licenses/GPL-3.0+
"""

# Other platforms are being built in GCCBootstrap
# platforms = supported_platforms()
# filter!(p -> !(os(p) == "macos" && arch(p) == "aarch64"), platforms)
platforms = Any[ Platform("x86_64", "linux"; sanitize="memory") ]

# The products that we will ensure are always built
products = LibraryProduct[
]

# Dependencies that must be installed before this package can be built
dependencies = Any[
    BuildDependency("LLVMCompilerRT_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
