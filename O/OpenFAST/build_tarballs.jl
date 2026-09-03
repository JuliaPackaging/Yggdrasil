# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenFAST"
version = v"4.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/OpenFAST/openfast.git", "89358f1843b62071ee1a8ca943c1b5277bcbd45a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openfast/

mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON \
-DBUILD_FASTFARM=OFF \
-DORCA_DLL_LOAD=OFF \
-DOPENMP=ON \
-DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
-DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(expand_gfortran_versions(supported_platforms(; experimental = true)))

# Filter out aarch64-linux-musl and aarch64-unknown-freebsd from platforms, this platform
# does not currently have IEEE_ARITHMETIC enabled for gfortran under the current configure
# set up see also: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100662
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)

# Filter out armv6l and armv7l
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)

# GCC 14 is required so filter out gfortran versions < 5
platforms = filter(p -> libgfortran_version(p) >= v"5", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libifw_c_binding", :libifw_c_binding),
    LibraryProduct("libmoordyn_c_binding", :libmoordyn_c_binding),
    LibraryProduct("libhydrodyn_c_binding", :libhydrodyn_c_binding),
    LibraryProduct("libaerodyn_inflow_c_binding", :libaerodyn_inflow_c_binding),
    ExecutableProduct("turbsim", :turbsim),
    ExecutableProduct("inflowwind_driver", :inflowwind_driver),
    ExecutableProduct("aerodyn_driver", :aerodyn_driver),
    ExecutableProduct("moordyn_driver", :moordyn_driver),
    ExecutableProduct("hydrodyn_driver", :hydrodyn_driver),
    ExecutableProduct("hydrodyn_driver", :hydrodyn_driver),
    # LibraryProduct("libaerodynlib", :libaerodynlib),
    # LibraryProduct("libelastodynlib", :libelastodynlib),
    # LibraryProduct("libopenfastlib", :libopenfastlib),
    # LibraryProduct("libmaplib", :libmaplib),
    # LibraryProduct("libbeamdynlib", :libbeamdynlib),
    # LibraryProduct("libnwtclibs", :libnwtclibs),
    # ExecutableProduct("inflowwind_driver", :inflowwind_driver),
    # LibraryProduct("libversioninfolib", :libversioninfolib),
    # LibraryProduct("libuaaerolib", :libuaaerolib),
    # ExecutableProduct("orca_driver", :orca_driver),
    # LibraryProduct("libmoordynlib", :libmoordynlib),
    # LibraryProduct("libmapcpplib", :libmapcpplib),
    # LibraryProduct("libwdlib", :libwdlib),
    # ExecutableProduct("feam_driver", :feam_driver),
    # ExecutableProduct("unsteadyaero_driver", :unsteadyaero_driver),
    # LibraryProduct("libextptfm_mckflib", :libextptfm_mckflib),
    # LibraryProduct("libscdataexlib", :libscdataexlib),
    # ExecutableProduct("turbsim", :turbsim),
    # LibraryProduct("libfvwlib", :libfvwlib),
    # LibraryProduct("libifwlib", :libifwlib),
    # ExecutableProduct("openfast", :openfast),
    # LibraryProduct("libafinfolib", :libafinfolib),
    # LibraryProduct("liborcaflexlib", :liborcaflexlib),
    # ExecutableProduct("aerodyn_driver", :aerodyn_driver),
    # LibraryProduct("libfoamfastlib", :libfoamfastlib),
    # LibraryProduct("libfeamlib", :libfeamlib),
    # LibraryProduct("libsctypeslib", :libsctypeslib),
    # LibraryProduct("libsubdynlib", :libsubdynlib),
    # ExecutableProduct("subdyn_driver", :subdyn_driver),
    # LibraryProduct("libopenfoamtypeslib", :libopenfoamtypeslib),
    # LibraryProduct("libaeroacoustics", :libaeroacoustics),
    # ExecutableProduct("dwm_driver_wind_farm", :dwm_driver_wind_farm),
    # LibraryProduct("libscdataextypeslib", :libscdataexttypeslib),
    # ExecutableProduct("moordyn_driver", :moordyn_driver),
    # LibraryProduct("libhydrodynlib", :libhydrodynlib),
    # LibraryProduct("libopenfast_postlib", :libopenfast_postlib),
    # LibraryProduct("libscfastlib", :libscfastlib),
    # LibraryProduct("libopenfast_prelib", :libopenfast_prelib),
    # LibraryProduct("libaerodyn14lib", :libaerodyn14lib),
    # ExecutableProduct("beamdyn_driver", :beamdyn_driver),
    # ExecutableProduct("servodyn_driver", :servodyn_driver),
    # LibraryProduct("libawaelib", :libawaelib),
    # LibraryProduct("libicedynlib", :libicedynlib),
    # LibraryProduct("libicefloelib", :libicefloelib),
    # LibraryProduct("libservodynlib", :libservodynlib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll")
    # Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"14", clang_use_ldd = false)
