# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ReadStat"
version = v"1.1.9"

sources = [
    GitSource("https://github.com/WizardMac/ReadStat.git",
              "104ba03a8da116eb8c094abc18bc2530b733eda9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# Add `gettext` for `autogen.sh`
apk update
apk add gettext-dev

# Fix "Undefined symbols for architecture arm64: "_libiconv","
export LDFLAGS="-L${libdir}"

export CPPFLAGS="-I${includedir}"

cd $WORKSPACE/srcdir/ReadStat/
# Revert spawnv non-sense.
atomic_patch ../patches/mingw-no-spawnv.patch
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("readstat", :readstat),
    LibraryProduct("libreadstat", :libreadstat),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
