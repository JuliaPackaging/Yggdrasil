# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BEDTools"
version = v"2.31.1"

sources = [
    GitSource("https://github.com/arq5x/bedtools2.git", "705ccfdf2c9a77d71560c8adcece0663c2f5e18e"),
]

script = raw"""
cd $WORKSPACE/srcdir/bedtools2/

# Remove git metadata so that the version is taken from `version_release.txt`.
rm -rf .git

# Only the main binary is built; the legacy wrapper scripts (e.g. `intersectBed`) require Python.
# Command-line variables propagate to the bundled htslib sub-make.
make -j${nproc} bin/bedtools \
    CC="${CC}" CXX="${CXX}" AR=ar RANLIB=ranlib \
    CPPFLAGS="-I${includedir}" LDFLAGS="-L${libdir}"

install -Dvm 755 bin/bedtools "${bindir}/bedtools${exeext}"
install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows))

products = [
    ExecutableProduct("bedtools", :bedtools),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    # Earlier versions of Bzip2_jll and XZ_jll have no riscv64 build.
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("XZ_jll"; compat="5.6.4"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
