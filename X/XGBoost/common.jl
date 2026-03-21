using BinaryBuilder
using BinaryBuilderBase
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

# Collection of sources required to build XGBoost
function get_sources()
    return [
        GitSource("https://github.com/dmlc/xgboost.git","62e7923619352c4079b24303b367134486b1c84f"),
        ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49")
    ]
end

# products we'll build (common to both CPU and GPU versions)
function get_products()
    return [
        LibraryProduct(["libxgboost", "xgboost"], :libxgboost)
    ]
end

# supported platforms for system
function get_platforms()
    return expand_cxxstring_abis(supported_platforms())
end

function get_dependencies(platform::Platform)
    dependencies = AbstractDependency[
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); 
            platforms=filter(!Sys.isbsd, [platform])),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); 
            platforms=filter(Sys.isbsd, [platform])),
        # builds are done in XGBoost using cmake v3.31 - this turns out to be necessary to include libomp via CompilerSupportLibraries_jll with the newer SDK
        HostBuildDependency(PackageSpec(name="CMake_jll"))
    ]
    return dependencies
end

# common install component of the script across both CPU and GPU builds
const install_script = raw"""
# Manual installation, to avoid installing dmlc
    for header in include/xgboost/*.h; do
        install -Dv "${header}" "${includedir}/xgboost/$(basename ${header})"
    done

if [[ ${target} == *mingw* ]]; then
    install -Dvm 0755 lib/xgboost.dll ${libdir}/xgboost.dll
else
    install -Dvm 0755 lib/libxgboost.${dlext} ${libdir}/libxgboost.${dlext}
fi

install_license LICENSE
"""