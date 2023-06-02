using BinaryBuilder, Pkg

name = "MUSCLE"
version = v"5.2"

sources = [
    GitSource("https://github.com/rcedgar/muscle.git",
                  "6c601163998616bb88991931e443c645858e162c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/muscle/src/
atomic_patch ${WORKSPACE}/srcdir/patches/remove-ffast-math.patch
make -j${nproc}
install -D -m 755 ${WORKSPACE}/srcdir/muscle/src/Linux/./muscle ${bindir}/./muscle
install_license ${WORKSPACE}/srcdir/muscle/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("muscle", :muscle),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
