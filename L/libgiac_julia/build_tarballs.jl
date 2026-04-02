# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

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

# Meson cross-compilation setup
# BinaryBuilder generates two meson cross-files per platform:
#   target_<triplet>_clang.meson  and  target_<triplet>_gcc.meson
# MESON_TARGET_TOOLCHAIN is a symlink to one of them (gcc on Linux/Windows,
# clang on macOS/FreeBSD).
#
# On macOS/FreeBSD: keep clang (default) to match libcxxwrap_julia_jll ABI.
# On Linux/Windows: explicitly select the GCC variant for GIAC_jll compatibility.
if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    MESON_CROSS="${MESON_TARGET_TOOLCHAIN}"
elif [[ -f "${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson" ]]; then
    # Replace .meson with _gcc.meson on the symlink path (e.g.
    # target_x86_64-linux-gnu.meson -> target_x86_64-linux-gnu_gcc.meson)
    MESON_CROSS="${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson"
else
    MESON_CROSS="${MESON_TARGET_TOOLCHAIN}"
fi

# Inject cmake path into the cross-file so meson can find JlCxx
CMAKE_PATH=$(which cmake)
sed -i "/^\[binaries\]/a cmake = '${CMAKE_PATH}'" "${MESON_CROSS}"

# Fix linker detection on macOS: meson tries -Wl,--version to detect the linker
# specified via c_ld/cpp_ld, but Apple's ld doesn't support --version.
# Remove these entries so meson auto-detects the linker through clang.
if [[ "${target}" == *apple* ]]; then
    sed -i "/^c_ld = /d" "${MESON_CROSS}"
    sed -i "/^cpp_ld = /d" "${MESON_CROSS}"
fi

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
    BuildDependency(name="libjulia_jll")
    Dependency("libcxxwrap_julia_jll"),
    Dependency("GIAC_jll"; compat="2.0.1"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10", julia_compat=libjulia_julia_compat(julia_versions))
