using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "VMEC"
upstream_version = v"1.2.0"
version_patch_offset = 0
version = VersionNumber(upstream_version.major,
                        upstream_version.minor,
                        upstream_version.patch * 100 + version_patch_offset)

sources = [
    ArchiveSource("https://gitlab.com/wistell/VMEC2000/-/archive/v$(upstream_version).tar",
                  "3b7db01868204855506ca8c33394fc3f6dea73d9d2594bf047fefc46d87b294b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/VMEC*
./autogen.sh
./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3 --build=${MACHTYPE}  --host=${target} --target=${target} --prefix=${prefix}
make && make install && make clean
"""

# This is for MPItrampoline implementation
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
    end
"""

platforms = expand_gfortran_versions(supported_platforms())

# Filter out libgfortran_version = 3.0.0 which is incompatible with VMEC
filter!(p ->libgfortran_version(p) >= v"4", platforms)

# Filter incompatible architectures and operating systems
filter!(p -> arch(p) == "x86_64", platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(!Sys.iswindows, platforms)

# Right now VMEC only works with libc=glibc, filter out any musl dependencies
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
# Don't automatically dl_open so that the appropriate 
# library can be loaded on intiation of VMEC.jl
products = [
    LibraryProduct("libvmec", :libvmec),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # MbedTLS is an indirect dependency, fix the version for building 
    BuildDependency(PackageSpec(name = "MbedTLS_jll")),
    Dependency("libblastrampoline_jll", compat = "3.0.4"),
    Dependency("SCALAPACK_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Needed from MPItrampoline
all_platforms, platform_dependencies = MPI.augment_platforms(platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.7", augment_platform_block)
