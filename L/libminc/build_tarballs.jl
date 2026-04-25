using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libminc"
version = v"2.5.0"

sources = [
    #ArchiveSource("https://github.com/BIC-MNI/libminc/archive/refs/tags/release-2.4.06.tar.gz", "cd5c6da9cd98be225a4bd3b8d712bd5292fc24f434cae732fa37af866c2db5b3"),
    GitSource("https://github.com/BIC-MNI/libminc.git","64e883811e12f860e9380a694e3df200e64d44ed") # release-2.5.0
    GitSource("https://github.com/NIST-MNI/minc2-simple.git","8f161e041ad968fc7bd71c0fba3fdba7f067b9e7") # v2.21.0
]

script = raw"""
cd ${WORKSPACE}/srcdir/libminc
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBMINC_BUILD_SHARED_LIBS:BOOL=ON \
    -DLIBMINC_MINC1_SUPPORT:BOOL=ON \
    -DBUILD_TESTING:BOOL=OFF \
    -DLIBMINC_USE_NIFTI:BOOL=OFF \
    -DLIBMINC_BUILD_EZMINC=OFF
make -j${nproc}
make install


cd ../../minc2-simple
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_TESTING:BOOL=OFF \
    -DLIBMINC_DIR:PATH=$prefix/lib/cmake
make -j${nproc}
make install
    

install_license ${WORKSPACE}/srcdir/libminc/COPYING
"""

platforms = supported_platforms()
platforms = filter(p -> Sys.islinux(p) && libc(p) == "glibc" && arch(p) == "x86_64" , platforms)
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)


# Augment platforms with all MPI variants for Yggdrasil
all_platforms = Platform[]
for p in platforms
    t = tags(p)
    extras = Dict(Symbol(k) => v for (k, v) in t if k ∉ ("arch", "os"))
    for mpi in ("mpitrampoline", "openmpi", "mpich")
        push!(all_platforms,
              Platform(arch(p), os(p); extras..., mpi=mpi))
    end
end
platforms = all_platforms


# Augment platforms with MPI tags — HDF5_jll/NetCDF_jll are MPI-aware
augment_platform_block = """
    using Base.BinaryPlatforms

    try
        using MPIPreferences
    catch
        # MPIPreferences not yet available
    end

    function augment_platform!(platform::Platform)
        haskey(platform, "mpi") && return platform
        if @isdefined(MPIPreferences)
            platform["mpi"] = MPIPreferences.abi
        else
            platform["mpi"] = "mpitrampoline"
        end
        return platform
    end
"""

products = [
    LibraryProduct("libminc2", :libminc2),
    LibraryProduct("libminc2-simple", :libminc2_simple)
]

dependencies = [
   Dependency("HDF5_jll";  compat="~1.14.6"), # should be compatible with NetCDF
   Dependency("NetCDF_jll";compat="~401.900.300"), 
   # Add MPI and gfortran dependencies explicitly
   Dependency("MPIPreferences"; compat="0.1"),
   Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
   HostBuildDependency(Pkg.PackageSpec(; name="CMake_jll")),
]


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    julia_compat="1.9" ,
    augment_platform_block, 
    preferred_gcc_version=v"5"
  )
