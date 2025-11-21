# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LSEOS"
version = v"2.7"

# Collection of sources required to complete build
sources = [
    # The original sources can currently not been accessed because we do not accept the server's certificate
    # ArchiveSource("https://www.astro.sunysb.edu/dswesty/lseos_v$(version.major).$(version.minor).tar.gz",
    #               "d729f8c2373a41194f171aeb0da0a9bb35ac181f31afa7e260786d19a500dea1"),
    GitSource("https://github.com/eschnett/lseos", "7ba561c80125612b679594404c2774ab04344513"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/lseos*
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/loadmx2.patch
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/ssflag.patch
${FC} -O -fPIC -shared -o liblseos.${dlext} lseos_v*.f
install -Dvm 755 liblseos.${dlext} ${libdir}/liblseos.${dlext}

install -Dvm 644 bd180.atb ${prefix}/etc/bd180.atb
install -Dvm 644 max180.atb ${prefix}/etc/max180.atb
install -Dvm 644 bd220.atb ${prefix}/etc/bd220.atb
install -Dvm 644 max220.atb ${prefix}/etc/max220.atb
install -Dvm 644 bd375.atb ${prefix}/etc/bd375.atb
install -Dvm 644 max375.atb ${prefix}/etc/max375.atb

install_license LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblseos", :liblseos),

    FileProduct("etc/bd180.atb", :bd180),
    FileProduct("etc/max180.atb", :max180),
    FileProduct("etc/bd220.atb", :bd220),
    FileProduct("etc/max220.atb", :max220),
    FileProduct("etc/bd375.atb", :bd375),
    FileProduct("etc/max375.atb", :max375),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
