# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TempestModel"
version = v"0.1"
sources = [
    GitSource("https://github.com/paullric/tempestmodel",
	      "4ecf5146f3100fb24d36156a2f99433f049f0f66"),
    DirectorySource("./bundled")
]

script = raw"""
mkdir -vp $bindir
mkdir -vp $libdir

cd ${WORKSPACE}/srcdir/tempestmodel*

atomic_patch -p1 ../patches/mk_defs.patch  
atomic_patch -p1 ../patches/mk_system_macosx.patch
# linux system fallback
atomic_patch -p1 ../patches/mk_system_agri.patch
atomic_patch -p1 ../patches/netcdf_cpp.patch

export CXXFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

make NETCDF_ROOT=$prefix -j${nproc} all

cp -v test/nonhydro_sphere/ScharMountainSphereTest ${bindir}
cp -v test/nonhydro_sphere/BaroclinicWaveJWTest ${bindir}
cp -v test/nonhydro_sphere/StationaryMountainFlowTest ${bindir}
cp -v test/nonhydro_sphere/MountainWaveSphereTest ${bindir}
cp -v test/nonhydro_sphere/HeldSuarezTest ${bindir}
cp -v test/nonhydro_sphere/InertiaGravityWaveTest ${bindir}
cp -v test/nonhydro_sphere/BaroclinicWaveUMJSTest ${bindir}
cp -v test/nonhydro_sphere/MountainRossby3DTest ${bindir}
cp -v test/nonhydro_sphere/BaldaufGravityWaveTest ${bindir}

cp -v test/nonhydro_xz/RobertBubbleCartesianTest ${bindir}
cp -v test/nonhydro_xz/ShearJetMtnWave2DCartesianTest ${bindir}
cp -v test/nonhydro_xz/ThermalBubbleCartesian3DTest ${bindir}
cp -v test/nonhydro_xz/Baroclinic3DCartesianTest ${bindir}
cp -v test/nonhydro_xz/DensityCurrentCartesianTest ${bindir}
cp -v test/nonhydro_xz/NonHydroMountainCartesianTest ${bindir}
cp -v test/nonhydro_xz/HydrostaticMountainCartesianTest ${bindir}
cp -v test/nonhydro_xz/ThermalBubbleCartesianTest ${bindir}
cp -v test/nonhydro_xz/Baroclinic3DCartesianRidgeTest ${bindir}
cp -v test/nonhydro_xz/ScharMountainCartesianTest ${bindir}
cp -v test/nonhydro_xz/InertialGravityCartesianXZTest ${bindir}

cp -v test/shallowwater_sphere/BarotropicInstabilityTest ${bindir}
cp -v test/shallowwater_sphere/MountainRossbyTest ${bindir}
cp -v test/shallowwater_sphere/RossbyHaurwitzWaveTest ${bindir}
"""

# Note: We are restricted to the platforms that NetCDF supports, the library is Unix only
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
] 
platforms = expand_cxxstring_abis(platforms)
  
products = [
    # non-hydro sphere test cases
    ExecutableProduct("ScharMountainSphereTest", :ScharMountainSphereTest_exe),
    ExecutableProduct("BaroclinicWaveJWTest", :BaroclinicWaveJWTest_exe),
    ExecutableProduct("StationaryMountainFlowTest", :StationaryMountainFlowTest_exe),
    ExecutableProduct("MountainWaveSphereTest", :MountainWaveSphereTest_exe),
    ExecutableProduct("HeldSuarezTest", :HeldSuarezTest_exe),
    ExecutableProduct("InertiaGravityWaveTest", :InertiaGravityWaveTest_exe),
    ExecutableProduct("BaroclinicWaveUMJSTest", :BaroclinicWaveUMJSTest_exe),
    ExecutableProduct("MountainRossby3DTest", :MountainRossby3DTest_exe),
    ExecutableProduct("BaldaufGravityWaveTest", :BaldaufGravityWaveTest_exe),

    # non-hydro xz test cases
    ExecutableProduct("RobertBubbleCartesianTest", :RobertBubbleCartesianTest_exe),
    ExecutableProduct("ShearJetMtnWave2DCartesianTest", :ShearJetMtnWave2DCartesianTest_exe),
    ExecutableProduct("ThermalBubbleCartesian3DTest", :ThermalBubbleCartesian3DTest_exe),
    ExecutableProduct("Baroclinic3DCartesianTest", :Baroclinic3DCartesianTest_exe),
    ExecutableProduct("DensityCurrentCartesianTest", :DensityCurrentCartesianTest_exe),
    ExecutableProduct("NonHydroMountainCartesianTest", :NonHydroMountainCartesianTest_exe),
    ExecutableProduct("HydrostaticMountainCartesianTest", :HydrostaticMountainCartesianTest_exe),
    ExecutableProduct("ThermalBubbleCartesianTest", :ThermalBubbleCartesianTest_exe),
    ExecutableProduct("Baroclinic3DCartesianRidgeTest", :Baroclinic3DCartesianRidgeTest_exe),
    ExecutableProduct("ScharMountainCartesianTest", :ScharMountainCartesianTest_exe),
    ExecutableProduct("InertialGravityCartesianXZTest", :InertialGravityCartesianXZTest_exe),

    # shallow water test cases
    ExecutableProduct("BarotropicInstabilityTest", :BarotropicInstabilityTest_exe), 
    ExecutableProduct("MountainRossbyTest", :MountainRossbyTest_exe),
    ExecutableProduct("RossbyHaurwitzWaveTest", :RossbyHaurwitzWaveTest_exe),
]

dependencies = [
    Dependency("MKL_jll"),
    Dependency("MPICH_jll"),
    Dependency("NetCDF_jll"; compat="400.701.400 - 400.799"),
    Dependency("HDF5_jll"),
    # `MbedTLS_jll` is an indirect dependency through NetCDF, we need to specify
    # a compatible build version for this to work.
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version=v"2.24.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
)
