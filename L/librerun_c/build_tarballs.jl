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


# The products that we will ensure are always built
products = [
    LibraryProduct("librerun_c", :librerun_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"15.2.0")
