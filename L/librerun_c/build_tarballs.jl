# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "librerun_c"
version = v"0.33.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rerun-io/rerun.git", "86ac19fac05672f094b6b59b824249983d8d2bb0"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done 
cd rerun

# ring (and similar cc-rs crates) compile native code for the host during the build;
# point cc-rs at the host compiler for the host target triple.
export CC_$(echo $rust_host | sed "s/-/_/g")=$CC_BUILD

# Link the system zstd (Zstd_jll) rather than zstd-sys's vendored copy, whose bundled C
# uses qsort_r — absent from BinaryBuilder's musl libc. Zstd_jll is already patched for it.
export ZSTD_SYS_USE_PKG_CONFIG=1
export PKG_CONFIG_ALLOW_CROSS=1

# Building a cdylib on musl requires disabling the default static-CRT linkage.
if [[ "${target}" == *musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

cmake . -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/rerun/LICENSE-APACHE
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Rust toolchain is not available for RISC-V
filter!(p -> arch(p) != "riscv64", platforms)
# Rust toolchain is not available for aarch64 FreeBSD
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)


# The products that we will ensure are always built
products = [
    # Rust names the cdylib `rerun_c.dll` on Windows, `librerun_c.{so,dylib}` elsewhere.
    LibraryProduct(["librerun_c", "rerun_c"], :librerun_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"15.2.0", lock_microarchitecture = false)
