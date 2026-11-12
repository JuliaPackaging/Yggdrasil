using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MicrosoftMPI"
version = v"10.1.3"
# Must exceed registered JLL v10.1.4, which already holds upstream 10.1.3
ygg_version = v"10.1.5"
sources = [
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisetup.exe",
               "47443829114d8d8670f77af98939fe876d33eceb35d0ce4e0e85efeec4d87213"),
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisdk.msi",
               "8ccbc77a0cfe1e30f7495a759886b4d99b2c494b9b9ad414dcda1da84c00d3fa"),
]

script = raw"""
apk add p7zip

cd ${WORKSPACE}/srcdir
7z x -t# msmpisetup.exe -osetup
7z x msmpisdk.msi -osdk
# The 64-bit MSI and SDK ship both architectures, with the 64-bit files suffixed "64"
if [[ ${nbits} == 32 ]]; then
    7z x setup/2.msi -oruntime
    suffix=""
    # The stdcall Fortran import libraries only exist for 32-bit
    import_libs="msmpi msmpifec msmpifes msmpifmc msmpifms"
else
    7z x setup/4.msi -oruntime
    suffix="64"
    import_libs="msmpi msmpifec msmpifmc"
fi

install -Dvm 755 runtime/*.exe -t ${bindir}
install -Dvm 755 runtime/msmpi${suffix}.dll ${libdir}/msmpi.dll
install -Dvm 755 runtime/msmpires${suffix}.dll ${libdir}/msmpires.dll
for lib in ${import_libs}; do
    install -Dvm 644 sdk/${lib}${suffix}.lib ${prefix}/lib/${lib}.lib
    if [[ -n ${suffix} ]]; then
        # Also keep the SDK's name, which consumers link as e.g. `-lmsmpi64`
        install -Dvm 644 sdk/${lib}${suffix}.lib -t ${prefix}/lib
    fi
done

# Replace the one non-ASCII byte in mpif.h (Latin-1 0xA0) by a space. Not a patch:
# the file is CRLF, and .gitattributes would convert a patch's context lines to LF.
LC_ALL=C sed -i $'s/\xa0/ /' sdk/mpif.h
install -Dvm 644 sdk/mpi.h sdk/mpio.h sdk/mpif.h sdk/mspms.h sdk/pmidbg.h runtime/mpitrace.man -t ${includedir}
install -Dvm 644 sdk/mpifptr${nbits}.h ${includedir}/mpifptr.h
install -Dvm 644 sdk/mpi.f90 -t ${prefix}/src

# Generate "mpi.mod", "mpi_base.mod", "mpi_sizeofs.mod" and "mpi_constants.mod"
cd ${includedir}
${FC} -I. ../src/mpi.f90 -fsyntax-only -fno-range-check

install_license \
    ${WORKSPACE}/srcdir/runtime/*.rtf \
    ${WORKSPACE}/srcdir/runtime/*.txt \
    ${WORKSPACE}/srcdir/sdk/*.rtf \
    ${WORKSPACE}/srcdir/sdk/*.txt
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms = filter!(Sys.iswindows, supported_platforms())
platforms = expand_gfortran_versions(platforms)

# Add `mpi+microsoftmpi` platform tag
for p in platforms
    p["mpi"] = "MicrosoftMPI"
end

products = [
    LibraryProduct("msmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
                      compat="0.1", top_level=true),
]

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
