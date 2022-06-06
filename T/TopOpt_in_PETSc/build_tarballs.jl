# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TopOpt_in_PETSc"
version = v"0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/topopt/TopOpt_in_PETSc", "26eecbf3b1d0135956e0364d77c30e43e9bc3db2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# New makefiles added, the patches fix some weird include issues mostly.
# There is likely a better way to fix them, or upstream the fixes.
script = raw"""
cd TopOpt_in_PETSc
make -f ../Makefile libtopopt.${dlext} topopt${exeext}
install -Dvm 755 "topopt${exeext}" "${bindir}/topopt${exeext}"
install -Dvm 755 "libtopopt.${dlext}" "${libdir}/libtopopt.${dlext}"
install_license lesser.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(exclude=[Platform("i686", "windows")]))

# The products that we will ensure are always built
products = [
    LibraryProduct("libtopopt", :libtopopt),
    ExecutableProduct("topopt", :topopt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PETSc_jll"; compat="3.16.5"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
