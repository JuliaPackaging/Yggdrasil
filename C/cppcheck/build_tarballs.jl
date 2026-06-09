# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cppcheck"
version = v"2.21.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/danmar/cppcheck.git", "e73bf44c3e49686b7495fab352d03a6c6075516b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cppcheck/

# cppcheck 2.21 requires CMake >= 3.22; remove the older system CMake so the
# newer JLL-provided one is used.
apk del cmake

mkdir build && cd build

# By default cppcheck hard-codes FILESDIR to $prefix/share/cppcheck (baked into
# the binary as an absolute path) and installs its data files (cfg/*.cfg,
# platforms/*.xml and the Python addons such as misra.py) there. That absolute
# path does not exist once the JLL is relocated. cppcheck also searches for
# those files *next to the executable* (exepath/cfg, exepath/addons,
# exepath/platforms) before falling back to FILESDIR, so install everything into
# $prefix/bin to get a fully relocatable package.
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DFILESDIR=$prefix/bin \
      -DBUILD_GUI=OFF \
      -DUSE_MATCHCOMPILER=OFF \
      -DDISABLE_DMAKE=ON \
      -DBUILD_TESTS=OFF \
      -DHAVE_RULES=ON \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(exclude=Sys.isfreebsd))

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("cppcheck", :cppcheck),
    # cppcheck's addons (misra.py, etc.) are installed next to the binary so they
    # are found relative to the executable after relocation. They are plain
    # Python scripts using only the standard library: running an addon needs a
    # `python3`/`python` on PATH at runtime (cppcheck shells out to it, or use
    # `--addon-python=<path>`). We deliberately do not bundle Python_jll, so
    # addons rely on whatever Python the user has available.
    FileProduct("bin/addons/misra.py", :misra_addon),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # cppcheck 2.21 requires CMake >= 3.22, newer than the one in the build
    # environment (used together with `apk del cmake` in the script above).
    HostBuildDependency("CMake_jll"),
    Dependency("PCRE_jll"; compat="8.44.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
# cppcheck 2.21 defaults its move constructors `noexcept` out-of-line, which
# requires every member's move to be `noexcept`. libstdc++ only made the
# unordered-container move constructors `noexcept` in GCC 11, so an older
# compiler fails to build `lib/settings.cpp`.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
