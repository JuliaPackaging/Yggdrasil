# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Modflow6"
version = v"6.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MODFLOW-USGS/modflow6.git",
              "43f6198125867c487eedc64b17e9adaceb73f5ab")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/modflow6*

# change ar for macOS, llvm-ar seems to generate corrupted static archives
# fix copied from https://github.com/JuliaPackaging/Yggdrasil/pull/3915/commits/b952adb6f936
if [[ "${target}" == *apple* ]]; then
    sed -i "s?^ar = .*?ar = '/opt/${target}/bin/${target}-ar'?g" "${MESON_TARGET_TOOLCHAIN}"
fi

meson -Ddebug=false -Doptimization=2 --cross-file=${MESON_TARGET_TOOLCHAIN} builddir
meson compile -C builddir -j${nproc}
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmf6", :libmf6),
    ExecutableProduct("mf6", :mf6),
    ExecutableProduct("zbud6", :zbud6),
    ExecutableProduct("mf5to6", :mf5to6)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
