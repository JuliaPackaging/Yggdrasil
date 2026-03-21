using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "p7zip"
# Upstream uses CalVer
upstream_version = "26.00"
compact_version = replace(upstream_version, "."=>"")
version = v"17.8.0"

# Collection of sources required to build p7zip
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/$(upstream_version)/7z$(compact_version)-src.tar.xz",
                  "3e596155744af055a77fc433c703d54e3ea9212246287b5b1436a6beac060f16";
                  unpack_target="7z"),
]

# Bash recipe for building across all platforms
script = raw"""
cd 7z/CPP/7zip/Bundles/Alone

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

# Require MacOS 10.13 or later to support utimensat
sources, script = require_macos_sdk("10.13", sources, script)

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
