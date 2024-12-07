# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = (dirname∘dirname∘dirname)(@__FILE__)
(include∘joinpath)(YGGDRASIL_DIR, "platforms", "mpi.jl")

name = "Kira"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/kira-pyred/kira.git", "8001d64f23406d6c4cb06578b89011c1a0c04c65"),
]

# Bash recipe for building across all platforms
script = raw"""
pip3 install -U meson

mkdir ${WORKSPACE}/srcdir/Kira-build
cd ${WORKSPACE}/srcdir/Kira-build/

meson setup \
    -Dfirefly=true \
    -Djemalloc=true \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --buildtype=release \
    ${WORKSPACE}/srcdir/kira/ \
    ${WORKSPACE}/srcdir/Kira-build/
sed -i "s?/workspace/destdir/opt?/opt?g" build.ninja

meson install
install_license ${WORKSPACE}/srcdir/kira/COPYING
"""

# augment_platform_block = """
#     using Base.BinaryPlatforms
#     $(MPI.augment)
#     augment_platform!(platform::Platform) = augment_mpi!(platform)
# """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; )
]   # Fermat may only support these platforms, which is the external program required to run Kira.
    # Therefore, I do not build Kira for other platforms, while Kira could be compliled on them.
    # Notice that aarch64 MacOS is running the Fermat via Rosetta 2.
    # It would be helpful if someone would be willing to help compile Fermat on more platforms.
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
# platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
# platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("kira", :kira)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FireFly_jll", uuid="8ecac4f1-ae1f-5ff6-b30b-37d818d8e8b3"))
    Dependency(PackageSpec(name="GiNaC_jll", uuid="f695d788-2582-5101-a7df-1403a8f3a07a"))
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="yaml_cpp_jll", uuid="01fea8cc-7d33-533a-824e-56a766f4ffe8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version = v"7.1.0"    # For `FireFly_jll`
)
