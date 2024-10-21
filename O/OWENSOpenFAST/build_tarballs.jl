# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OWENSOpenFAST"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    # GitSource("https://github.com/andrew-platt/openfast.git", "853ba8ca9f82d8bf1552638f9fa82af750750952"), # main
    GitSource("https://github.com/andrew-platt/openfast.git", "24c05a744f9d93877a7f7ac32adef469b3cd8269"), # PR
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openfast/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-lowercase-windows-include.patch
fi

mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON \
-DBUILD_FASTFARM=OFF \
-DORCA_DLL_LOAD=OFF \
-DOPENMP=OFF \
-DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
-DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}"

#WARNING: compiling this locally can go crazy and lock up your machine, using only 2 jobs and Debug version to make it behave
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = expand_cxxstring_abis(expand_gfortran_versions(supported_platforms(; experimental = true)))
# platforms = expand_gfortran_versions(supported_platforms(; experimental=true))

# remove aarch64-linux-musl from platforms, this platform does not currently have IEEE_ARITHMETIC enabled for gfortran under the current configure set up
# see also: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100662
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl"), platforms)

# remove aarch-apple-darwin platforms, same issue as aarch64-linux-musl
# filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# filter arm platforms
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)

# filter windows platforms - MinGW is not well supported relative to MSVC
# filter!(p -> !Sys.iswindows(p), platforms)

# TODO: These platforms work, just filtering out while iterating on broken ones
filter!(!Sys.islinux, platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "x86_64"), platforms)

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
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll")
    # Dependency(PackageSpec(name="OpenBLAS_jll"))#, uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
