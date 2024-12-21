using BinaryBuilder, Pkg

name = "HelloWorldFortran"
version = v"1.1.1"

# No sources, we're just building the testsuite
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
f77 -o ${prefix}/bin/hello_world${exeext} -g -O2 /usr/share/testsuite/fortran/hello_world/hello_world.f
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
