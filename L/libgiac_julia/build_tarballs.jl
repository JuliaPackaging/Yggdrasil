# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libgiac_julia"
version = v"0.5.0"

# Collection of sources required to build libgiac_julia
sources = [
    GitSource(
        "https://github.com/s-celles/libgiac-julia-wrapper.git",
        "490207923b75678ace5409e16ed5bc134bd9c7d9"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgiac-julia-wrapper

# Use BinaryBuilder's default meson cross-file:
# gcc on Linux/Windows, clang on macOS/FreeBSD.
MESON_CROSS="${MESON_TARGET_TOOLCHAIN}"

# Meson's cmake module requires cmake in the cross-file's [binaries] section
# for cross-compilation. Inject the system cmake path.
sed -i "/^\[binaries\]/a cmake = '$(which cmake)'" "${MESON_CROSS}"

# Tell meson where to find JlCxx (libcxxwrap-julia) via CMake
# and where GIAC headers are installed
# Pass Julia headers include path via meson cpp_args (cross builds ignore env CXXFLAGS)
meson setup builddir \
    --cross-file="${MESON_CROSS}" \
    --prefix="${prefix}" \
    --buildtype=release \
    -Dgiac_include_dir="${includedir}/giac" \
    -Dcpp_args="-I${includedir}/julia -I${includedir}/giac" \
    -Dcpp_link_args="-L${libdir}" \
    --cmake-prefix-path="${prefix}"

# Build only the wrapper library target. Test executables (test_eval, etc.)
# are skipped because they require a Julia runtime unavailable in cross-compilation.
meson compile -C builddir -j${nproc} giac_wrapper

# Install without rebuilding: meson install normally recompiles ALL targets
# (including tests) before installing. --no-rebuild installs only what was
# already compiled above, avoiding test compilation failures.
meson install -C builddir --no-rebuild

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac_wrapper", :libgiac_wrapper),
]

# We do not provide all the compats since julia_version is in use
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14"),
    Dependency("GIAC_jll"; compat="2.0.1"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    clang_use_lld=false, preferred_gcc_version=v"10", julia_compat=libjulia_julia_compat(julia_versions))
