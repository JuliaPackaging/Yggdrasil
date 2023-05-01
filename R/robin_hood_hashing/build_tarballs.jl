using BinaryBuilder

# This is a header-only library.
name = "robin_hood_hashing"
version = v"3.11.5"

sources = [GitSource("https://github.com/martinus/robin-hood-hashing", "9145f963d80d6a02f0f96a47758050a89184a3ed")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/robin-hood-hashing
install -Dv src/include/robin_hood.h "${includedir}/robin_hood.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = [FileProduct("include/robin_hood.h", :robin_hood_h)]
dependencies = Dependency[]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5", julia_compat="1.6")
