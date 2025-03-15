# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

name = "normaliz"
version = v"300.1000.201"
upstream_version = v"3.10.2"

# Collection of sources required to complete build
sources = [
    #ArchiveSource("https://github.com/Normaliz/Normaliz/releases/download/v$(upstream_version)/normaliz-$(upstream_version).tar.gz",
    #              "365e1d1e2a338dc4df1947a440e606bb66dd261307e617905e8eca64eaafcf6e"),
    GitSource("https://github.com/Normaliz/Normaliz.git",
              "3bc242209e82488886eada17006e372fd89aa032"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ?ormaliz*

[ -e configure ] || ./bootstrap.sh

./configure --prefix=$prefix \
            --host=$target \
            --build=${MACHTYPE} \
            --with-flint=$prefix \
            --with-nauty=$prefix \
            --with-gmp=$prefix \
            --enable-openmp \
            CPPFLAGS=-I$prefix/include \
            LDFLAGS=-L${libdir}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# windows build would require MPIR instead of GMP for 'long long'
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) != "riscv64", platforms)  # missing FLINT
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libnormaliz", :libnormaliz),
    ExecutableProduct("normaliz", :normaliz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("OpenBLAS32_jll", v"0.3.28"),
    Dependency("FLINT_jll"; compat = "~300.200.0"),
    Dependency("nauty_jll"; compat = "~2.8.10"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems),
    # and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6", clang_use_lld=false)
