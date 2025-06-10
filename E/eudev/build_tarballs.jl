# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eudev"
version = v"3.2.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eudev-project/eudev", "9e7c4e744b9e7813af9acee64b5e8549ea1fbaa3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eudev*
apk add libxslt-dev docbook-xsl
./autogen.sh

# Only apply the patch for musl targets
if [[ "${target}" == *"musl"* ]]; then
    echo "Applying musl-specific thread_local fix"
    find . -name "*.c" -exec grep -l "thread_local" {} \; | xargs -r sed -i 's/thread_local/__thread/g'
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libudev", :libudev),
    ExecutableProduct("udevd", :udevd, "sbin"),
    ExecutableProduct("udevadm", :udevadm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
