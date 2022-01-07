# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "STL"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eschnett/STL.jl", "76f5f5eeaa0b789010b302ca5cf9d8551e3c83fb"),
    GitSource("https://github.com/eschnett/TestAbstractTypes.jl", "a23107bf47796db9d414c77801c6b3331f4950f0"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.5-musl-x86_64.tar.gz",
                  "e38eece6f9f20c7472caf3f8f74a99ad0880921c28e1301461fa7af919880383"),
]

# Bash recipe for building across all platforms
script = raw"""
export PATH="${PATH}:${WORKSPACE}/srcdir/julia-1.6.5/bin"

# Switch into source directory
cd STL.jl

# Create C++ wrapper code
julia --project=@. --eval '
    using Pkg

    oldpwd = pwd()
    cd("..")
    Pkg.generate("STL_jll")
    write("STL_jll/src/STL_jll.jl",
        \"\"\"
        module STL_jll
        # Just a placeholder library name
        const libSTL = "libSTL"
        export libSTL
        end
        \"\"\")
    cd(oldpwd)

    # Replace `STL_jll` which may not yet exist
    Pkg.rm("STL_jll")
    # Replace `TestAbstractTypes` which is not registered yet
    Pkg.rm("TestAbstractTypes")

    Pkg.develop(path="../STL_jll")
    Pkg.develop(path="../TestAbstractTypes.jl")

    # Pkg.build("STL")
    using STL
    STL.cxx_write_code!()
'

# Build and install C++ wrapper code
${CXX} -Drestrict=__restrict__ -std=c++17 -g -O2 -fPIC -shared -o ${libdir}/libSTL.${dlext} \
    StdMap.cxx StdSharedPtr.cxx StdString.cxx StdVector.cxx
install_license LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libSTL", :libSTL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
