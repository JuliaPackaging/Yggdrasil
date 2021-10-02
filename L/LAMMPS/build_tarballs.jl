# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LAMMPS"
version = v"1.0.0" # Equivalent to 2020-10-29

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "88fd96ec52f86dba4b222623f3a06632a32e42f1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lammps/
mkdir build && cd build/
cmake ../cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DPKG_SNAP=ON
make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi
"""

function configure(julia_version, llvm_version)
    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
    filter!(p -> libc(p) != "musl", platforms)

    foreach(platforms) do p
        BinaryPlatforms.add_tag!(p.tags, "julia_version", string(julia_version))
    end

    # The products that we will ensure are always built
    products = [
        LibraryProduct("liblammps", :liblammps),
        ExecutableProduct("lmp", :lmp),
        ]

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
        HostBuildDependency(get_addable_spec("LLVM_full_jll", llvm_version))
    ]

    return platforms, products, dependencies
end

# TODO: Don't require build-id on LLVM version
supported = (
    (v"1.6", v"11.0.1+3"),
    (v"1.7", v"12.0.0+0"),
    (v"1.8", v"12.0.0+0"),
)


for (julia_version, llvm_version) in supported
    platforms, products, dependencies = configure(julia_version, llvm_version)

    any(should_build_platform.(triplet.(platforms))) || continue

    # Build the tarballs.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                preferred_gcc_version=v"8", julia_compat="1.6")
end