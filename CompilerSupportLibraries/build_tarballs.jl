using BinaryBuilder

name = "CompilerSupportLibraries"
version = v"0.1.4"

# Collection of sources required to build Ogg
sources = [
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${target} == *mingw* ]]; then
    libdir=${prefix}/bin
else
    libdir=${prefix}/lib
fi
mkdir -p ${libdir}

# copy all the libraries
cp -v /opt/${target}/${target}/lib*/*.${dlext} ${libdir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gcc_versions(supported_platforms())

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libstdc++", :libstdcpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
