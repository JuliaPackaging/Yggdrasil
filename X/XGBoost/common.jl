using BinaryBuilder
using BinaryBuilderBase
using Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

# Collection of sources required to build XGBoost
function get_sources()
    return [
        GitSource("https://github.com/dmlc/xgboost.git","62e7923619352c4079b24303b367134486b1c84f"), # v2.1.4
        # for apple systems, we can't build from source - instead, use pre-built wheels from XGBoost itself
        FileSource("https://files.pythonhosted.org/packages/b6/fe/7a1d2342c2e93f22b41515e02b73504c7809247b16ae395bd2ee7ef11e19/xgboost-2.1.4-py3-none-macosx_10_15_x86_64.macosx_11_0_x86_64.macosx_12_0_x86_64.whl",
                    "78d88da184562deff25c820d943420342014dd55e0f4c017cc4563c2148df5ee";
                    filename = "xgboost-x86_64-apple-darwin14.whl"),
        FileSource("https://files.pythonhosted.org/packages/f5/b6/653a70910739f127adffbefb688ebc22b51139292757de7c22b1e04ce792/xgboost-2.1.4-py3-none-macosx_12_0_arm64.whl",
                    "523db01d4e74b05c61a985028bde88a4dd380eadc97209310621996d7d5d14a7";
                    filename = "xgboost-aarch64-apple-darwin20.whl")
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

function get_dependencies(platform::Platform; cuda::Bool = false, cuda_version::VersionNumber = v"12.0")
    dependencies = AbstractDependency[
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); 
            platforms=filter(!Sys.isbsd, [platform])),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); 
            platforms=filter(Sys.isbsd, [platform]))
    ]

    # dependencies necessary to build CUDA support
    if cuda
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))))
        append!(dependencies, CUDA.required_dependencies(platform))
    end

    return dependencies
end

# common install component of the script across both CPU and GPU builds
const install_script = raw"""
# Manual installation, to avoid installing dmlc
if [[ "${target}" != *apple-darwin* ]]; then
    for header in include/xgboost/*.h; do
        install -Dv "${header}" "${includedir}/xgboost/$(basename ${header})"
    done
fi

if [[ ${target} == *mingw* ]]; then
    install -Dvm 0755 lib/xgboost.dll ${libdir}/xgboost.dll
else
    install -Dvm 0755 lib/libxgboost.${dlext} ${libdir}/libxgboost.${dlext}
fi

install_license LICENSE
"""