using BinaryBuilder

name = "HelloWorldC"
version = v"1.2.4"

# 1.2.2: gcc 6
# 1.2.3: gcc 7
# 1.2.4: gcc 8

# No sources, we're just building the testsuite
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${bindir}
cc -L${prefix}/lib -o ${prefix}/bin/hello_world${exeext} -g -O2 /usr/share/testsuite/c/hello_world/hello_world.c

install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
