# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# libModelicaExternalC: the external C functions of the Modelica Standard Library (tables, strings,
# I/O, MAT files, random numbers, FFT) and an implementation of ModelicaUtilities.h, in one shared
# library. Built by the script of OMRuntimeExternalC.jl (deps/build_libraries.sh), which compiles the
# MSL C sources with the shim src/C/ModelicaCallbacks.c. The library links only the platform's libc.
using BinaryBuilder

name = "ModelicaExternalC"
version = v"4.1.0"  # the Modelica Standard Library release of the C sources

sources = [
    GitSource("https://github.com/modelica/ModelicaStandardLibrary.git",
              "8ae3d35c24e519cb2996cab20f3b13daf2b0c50a";
              tag="v$(version)"),
    # OpenModelica/OMRuntimeExternalC.jl: deps/build_libraries.sh and src/C/ModelicaCallbacks.c
    GitSource("https://github.com/OpenModelica/OMRuntimeExternalC.jl.git",
              "fff32815408fcfb9ff3f578c35a8891964555674"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
case "${target}" in
    *-apple-*) export TARGET_OS=Darwin ;;
    *-mingw*)  export TARGET_OS=MINGW ;;
    *)         export TARGET_OS=Linux ;;  # Linux (glibc, musl) and FreeBSD: ELF, the same linker flags
esac
OMRuntimeExternalC.jl/deps/build_libraries.sh ModelicaStandardLibrary/Modelica/Resources/C-Sources build
install -Dvm755 "build/libModelicaExternalC.${dlext}" "${libdir}/libModelicaExternalC.${dlext}"
install_license ModelicaStandardLibrary/LICENSE OMRuntimeExternalC.jl/LICENSE.md OMRuntimeExternalC.jl/THIRD_PARTY_LICENSES.md
"""

platforms = supported_platforms()

# dont_dlopen: OMRuntimeExternalC.jl loads the library itself, with RTLD_GLOBAL (compiled external C
# code of a Modelica model calls ModelicaError etc. from it), and only one copy: the JLL's, or a local
# build the user points it to.
products = [
    LibraryProduct("libModelicaExternalC", :libModelicaExternalC; dont_dlopen = true),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6")
