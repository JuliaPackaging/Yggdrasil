using BinaryBuilder, Pkg

name = "p7zip"
# Upstream uses CalVer
upstream_version = "25.01"
compact_version = replace(upstream_version, "."=>"")
version = v"17.7.0"

# Collection of sources required to build p7zip
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/$(upstream_version)/7z$(compact_version)-src.tar.xz",
                  "ed087f83ee789c1ea5f39c464c55a5c9d4008deb0efe900814f2df262b82c36e";
                  unpack_target="7z"),
    FileSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
        "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# Require MacOS 10.13 or later to support utimensat
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # need to run with BINARYBUILDER_RUNNER="privileged" for this rm to work
    rm -rf /opt/${target}/${target}/sys-root/System
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX10.13.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX10.13.sdk/System MacOSX10.13.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=10.13
fi

cd 7z/CPP/7zip/Bundles/Alone

# Lowercase names for MinGW
sed -i "s/NTSecAPI.h/ntsecapi.h/" ../../../Windows/SecurityUtils.h
sed -i 's/-lUser32/-luser32/g' ../../7zip_gcc.mak
sed -i 's/-lOle32/-lole32/g' ../../7zip_gcc.mak
sed -i 's/-lGdi32/-lgdi32/g' ../../7zip_gcc.mak
sed -i 's/-lComctl32/-lcomctl32/g' ../../7zip_gcc.mak
sed -i 's/-lComdlg32/-lcomdlg32/g' ../../7zip_gcc.mak
sed -i 's/-lShell32/-lshell32/g' ../../7zip_gcc.mak

# RAR has a custom license
export DISABLE_RAR=1

if [[ "${target}" == *-mingw* ]]; then
    export IS_MINGW=1
    export RC=windres
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # For some reason USE_ASM doesn't work on this platform
    make -j${nproc} -f makefile.gcc
else
    if [[ "${target}" == x86_64-* ]]; then
        make -j${nproc} -f makefile.gcc IS_X64=1 USE_ASM=1 MY_ASM="uasm"
    elif [[ "${target}" == aarch64-* ]]; then
        make -j${nproc} -f makefile.gcc IS_ARM64=1 USE_ASM=1
    else
        make -j${nproc} -f makefile.gcc
    fi
fi

install -Dvm 755 _o/7za${exeext} "${bindir}/7z${exeext}"
install_license ../../../../DOC/copying.txt
install_license ../../../../DOC/License.txt
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("7z", :p7zip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="UASM_jll", uuid="bbf38c07-751d-5a2b-a7fc-5c0acd9bd57e")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",                    # Minimum Julia version
    preferred_gcc_version=v"8",            # GCC version
)
