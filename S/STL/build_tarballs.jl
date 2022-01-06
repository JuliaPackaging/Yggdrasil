# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "STL"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eschnett/STL.jl", "81f53d9467c75111d5b937823f3ad713b1f4f78a"),
    # DirectorySource("/Users/eschnett/.julia/dev/STL"; target="STL.jl"),
    GitSource("https://github.com/eschnett/TestAbstractTypes.jl", "a23107bf47796db9d414c77801c6b3331f4950f0"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.5-musl-x86_64.tar.gz",
                  "e38eece6f9f20c7472caf3f8f74a99ad0880921c28e1301461fa7af919880383"),
]

# Bash recipe for building across all platforms
script = raw"""
export PATH="${PATH}:${WORKSPACE}/srcdir/julia-1.6.5/bin"

# Switch into source directory
cd STL.jl
rm -f Manifest.toml

# Create C++ wrapper code
julia --project=@. --eval '
    using Pkg

    oldpwd = pwd()
    cd("..")
    Pkg.generate("STL_jll")
    write("STL_jll/src/STL_jll.jl",
        \"\"\"
        module STL_jll
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

    Pkg.build("STL")
'

# Build C++ wrapper code
$CXX -Drestrict=__restrict__ -std=c++17 -shared -o libSTL.$dlext \
    deps/StdMap.cxx deps/StdSharedPtr.cxx deps/StdString.cxx deps/StdVector.cxx

# Install C++ wrapper code
cp libSTL.$dlext $libdir
mkdir -p $prefix/share/licenses/STL
cp LICENSE.md $prefix/share/licenses/STL
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
