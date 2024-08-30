using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "proxTV"
version = v"3.3.0"

# Collection of sources required to build proxTV.
sources = [
    GitSource("https://github.com/albarji/proxTV", "0b8973cd7e1a2348c842393f689949eeebc9f654"),
]

# Bash recipe for building across all platforms
# We build manually because the default build system
# is Python's setuptools.
script = raw"""
cd $WORKSPACE/srcdir/proxTV/src

if [[ "${target}" == *mingw* ]]; then
  LBT="${libdir}/libblastrampoline-5.dll"
else
  LBT="-lblastrampoline"
fi

${CXX} -DNOMATLAB -c -fPIC -I${includedir} *.cpp
${CXX} -shared -o libproxtv.${dlext} ${LBT} *.o

install -Dvm 755 libproxtv.${dlext} -t ${libdir}

install_license ../LICENSE.txt
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libproxtv", :libproxtv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
