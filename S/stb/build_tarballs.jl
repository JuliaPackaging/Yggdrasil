# Build script for stb: C++ header-only single-file utilities.
# This is basically just a dummy package that installs header files, and makes
# them available for other packages.

using BinaryBuilder


name = "stb"
# stb doesn't ever do releases, so the best we can do is stick to a specific git
# revision...
version = v"0.0.20261119"
sources = [
    GitSource("https://github.com/nothings/stb.git", "6b5799bae8a1fe3792691ef4b72ae26434c3e799"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/stb*/
mkdir -p "${includedir}"
cp -vr *.h "${includedir}/."
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = [AnyPlatform()]

# Header-only
products = Product[]

# Dependencies that must be installed before this package can be built.
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
