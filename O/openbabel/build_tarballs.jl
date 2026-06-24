# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "openbabel"
version = v"3.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openbabel/openbabel.git", "cbd4db43f8908b874864280fdc03bf92569eebc1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openbabel
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("obfit", :obfit),
    ExecutableProduct("obspectrophore", :obspectrophore),
    ExecutableProduct("roundtrip", :roundtrip),
    ExecutableProduct("obprop", :obprop),
    ExecutableProduct("obgrep", :obgrep),
    ExecutableProduct("obsym", :obsym),
    ExecutableProduct("obabel", :obabel),
    ExecutableProduct("obthermo", :obthermo),
    LibraryProduct("libopenbabel", :libopenbabel),
    ExecutableProduct("obfitall", :obfitall),
    ExecutableProduct("obprobe", :obprobe),
    ExecutableProduct("obminimize", :obminimize),
    ExecutableProduct("obrotamer", :obrotamer),
    ExecutableProduct("obdistgen", :obdistgen),
    ExecutableProduct("obgen", :obgen),
    ExecutableProduct("obenergy", :obenergy),
    ExecutableProduct("obrms", :obrms),
    ExecutableProduct("obrotate", :obrotate),
    ExecutableProduct("obconformer", :obconformer),
    ExecutableProduct("obmm", :obmm),
    ExecutableProduct("obtautomer", :obtautomer),
    LibraryProduct("libinchi", :libinchi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
