using BinaryBuilder, Pkg

name = "MKL_Pardiso"
version = v"2024.2.0"

sources = [
    GitSource("https://github.com/amontoison/MKL_Pardiso.git", "cb70bc69c426a67ef9e4dd0fd526963d594600fb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MKL_Pardiso
${CC} -fPIC -shared -o ${libdir}/libmkl_pardiso_shim.${dlext} mkl_pardiso_shim.c -L${libdir} -lmkl_rt
${CC} -fPIC -shared -o ${libdir}/libmkl_pardiso.${dlext} mkl_pardiso.c -L${libdir} -lmkl_pardiso_shim
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libmkl_pardiso", :libmkl_pardiso),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MKL_jll", uuid="856f044c-d86e-5d09-b602-aeab76dc8ba7"); compat="=$version"),
    BuildDependency(PackageSpec(name="MKL_Headers_jll", uuid="b2f2f022-7a59-54f4-945e-e9b78c3fd545"; version=version)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
