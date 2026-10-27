using BinaryBuilder

name = "OpenFAST"
version = v"5.0.0"

sources = [
    GitSource("https://github.com/OpenFAST/openfast.git", "2895884d2be01862173c88d70f86b358d2f1a50a"; tag="v$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/openfast

# ModVar uses the COTAN intrinsic, which older GFortran enables with -fdec-math.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_FLAGS="${FFLAGS} -fdec-math" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_FASTFARM=OFF \
    -DBUILD_OPENFAST_CPP_API=OFF \
    -DWIN_DLL_LOAD=OFF \
    -DOPENMP=OFF \
    -DBLAS_LIBRARIES="${libdir}/libblastrampoline.${dlext}" \
    -DLAPACK_LIBRARIES="${libdir}/libblastrampoline.${dlext}"
cmake --build build --parallel ${nproc}
cmake --install build

# Child processes need their own LP64 backend; Julia's LBT forwarding is process-local.
for exe in hydrodyn_driver inflowwind_driver orca_driver feam_driver unsteadyaero_driver \
    turbsim openfast aerodyn_driver subdyn_driver moordyn_driver beamdyn_driver servodyn_driver; do
    install -Dvm 755 "${bindir}/${exe}" "${prefix}/libexec/openfast/${exe}"
    cat > "${bindir}/${exe}" <<EOF
#!/bin/sh
export LBT_DEFAULT_LIBS="\${LBT_DEFAULT_LIBS-libopenblas.${dlext}}"
exec "\$(dirname "\$0")/../libexec/openfast/${exe}" "\$@"
EOF
done

install_license LICENSE \
    modules/map/src/bstring/bstrlib.h \
    modules/map/src/simclist/simclist.h \
    modules/map/src/lapack/lapacke.h \
    modules/nwtc-library/include/fast_float.h \
    ${WORKSPACE}/srcdir/licenses/CopyrightMINPACK.txt
"""

platforms = supported_platforms()
# GFortran's IEEE_ARITHMETIC support is missing on these targets with the older toolchains.
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100662
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isapple(p)), platforms)
# The aarch64 FreeBSD GFortran toolchain lacks ieee_arithmetic.mod.
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
# 32-bit ARM support is unvalidated.
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)
# MinGW support is unvalidated.
filter!(p -> !Sys.iswindows(p), platforms)
platforms = expand_gfortran_versions(platforms)

# Most internal module libraries are explicitly static in upstream CMake.
products = [
    LibraryProduct("libopenfastlib", :libopenfastlib),
    LibraryProduct("libaerodyn_inflow_c_binding", :libaerodyn_inflow_c_binding),
    LibraryProduct("libifw_c_binding", :libifw_c_binding),
    LibraryProduct("libhydrodyn_c_binding", :libhydrodyn_c_binding),
    LibraryProduct("libmoordyn_c_binding", :libmoordyn_c_binding),
    LibraryProduct("libseastate_c_binding", :libseastate_c_binding),
    ExecutableProduct("hydrodyn_driver", :hydrodyn_driver),
    ExecutableProduct("inflowwind_driver", :inflowwind_driver),
    ExecutableProduct("orca_driver", :orca_driver),
    ExecutableProduct("feam_driver", :feam_driver),
    ExecutableProduct("unsteadyaero_driver", :unsteadyaero_driver),
    ExecutableProduct("turbsim", :turbsim),
    ExecutableProduct("openfast", :openfast),
    ExecutableProduct("aerodyn_driver", :aerodyn_driver),
    ExecutableProduct("subdyn_driver", :subdyn_driver),
    ExecutableProduct("moordyn_driver", :moordyn_driver),
    ExecutableProduct("beamdyn_driver", :beamdyn_driver),
    ExecutableProduct("servodyn_driver", :servodyn_driver),
]

dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
    RuntimeDependency("OpenBLAS32_jll"; compat="0.3.23"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", preferred_gcc_version=v"8")
