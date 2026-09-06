using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_Runtime"
version = v"0.24.4"

# we ship artifacts for both GA and EA/preview toolkits; the platform augmentation only
# ever selects the latter when the user asks for it through the "version" preference.
const toolkit_versions = [CUDA.cuda_full_versions; CUDA.cuda_prerelease_versions]

augment_platform_block = """
    const CUDA_jll_uuids = [Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")]
    $(read(joinpath(@__DIR__, "toolkit_selection.jl"), String))
    const cuda_toolkits = $(toolkit_versions)
    const cuda_prerelease_toolkits = $(CUDA.cuda_prerelease_versions)
    $(read(joinpath(@__DIR__, "platform_augmentation.jl"), String))"""

script = raw"""
# rename directories, stripping the architecture and version suffix
for dir in *-archive; do
    base=$(echo $dir | cut -d '-' -f 1)
    mv $dir $base
done

# license
install_license cuda_cudart/LICENSE

# binaries
mkdir -p ${bindir} ${libdir} ${prefix}/lib ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    mv cuda_cudart/lib/libcudart.so* ${libdir}

    mv cuda_cupti/lib/libcupti.so* ${libdir}
    mv cuda_cupti/lib/libnvperf_host.so* ${libdir}
    mv cuda_cupti/lib/libnvperf_target.so* ${libdir}

    mv libcufft/lib/libcufft.so* libcufft/lib/libcufftw.so* ${libdir}

    mv libcublas/lib/libcublas.so* libcublas/lib/libcublasLt.so* ${libdir}

    mv libcusparse/lib/libcusparse.so* ${libdir}

    mv libcusolver/lib/libcusolver.so* libcusolver/lib/libcusolverMg.so* ${libdir}

    mv libcurand/lib/libcurand.so* ${libdir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    # starting with CUDA 13, there's an additionally `x64` subdirectory. remove it.
    find . -name x64 -type d -execdir sh -c 'mv x64/* .' \;

    # older versions of the redist binaries had DLLs in the lib folder; correct that
    for dir in */; do
        mkdir -p $dir/bin $dir/lib
        mv $dir/lib/*.dll $dir/bin || true
    done

    mv cuda_cudart/bin/cudart64_*.dll ${bindir}

    mv cuda_cupti/bin/cupti64_*.dll ${bindir}
    mv cuda_cupti/bin/nvperf_host.dll* ${libdir}
    mv cuda_cupti/bin/nvperf_target.dll* ${libdir}

    mv libcufft/bin/cufft64_*.dll libcufft/bin/cufftw64_*.dll ${bindir}

    mv libcublas/bin/cublas64_*.dll libcublas/bin/cublasLt64_*.dll ${bindir}

    mv libcusparse/bin/cusparse64_*.dll ${bindir}

    mv libcusolver/bin/cusolver64_*.dll libcusolver/bin/cusolverMg64_*.dll ${bindir}

    mv libcurand/bin/curand64_*.dll ${bindir}

    # Fix permissions
    chmod +x ${bindir}/*.dll
fi
"""

# determine exactly which tarballs we should build
builds = []
for version in reverse(toolkit_versions)
    include("build_$(version.major).$(version.minor).jl")

    # CUDA_Runtime contains all of the following components
    # XXX: consider splitting these into separate packages once BinaryBuilder supports it
    components = [
        "cuda_cudart",
        "cuda_cupti",

        "libcublas",
        "libcufft",
        "libcurand",
        "libcusolver",
        "libcusparse",
    ]

    platforms = if version >= v"13"
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"),
         Platform("x86_64", "windows")]
    else
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"; cuda_platform="jetson"),
         Platform("aarch64", "linux"; cuda_platform="sbsa"),
         Platform("x86_64", "windows")]
    end

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(version)

        should_build_platform(triplet(augmented_platform)) || continue

        if arch(platform) == "aarch64"
            # CUDA 10.x: our CUDA 10.2 build recipe for arm64 only provides jetson binaries
            if thisminor(version) == v"10.2" && platform["cuda_platform"] != "jetson"
                continue
            end

            # CUDA 11.x: only 11.8 has jetson binaries on the redist server
            if v"11.0" <= thisminor(version) < v"11.8" && platform["cuda_platform"] == "jetson"
                continue
            end

            # CUDA 12.x: the jetson binaries for 12.3 seem to be missing
            if thisminor(version) == v"12.3" && platform["cuda_platform"] == "jetson"
                continue
            end
        end

        if Base.thisminor(version) == v"10.2"
            push!(builds,
                (; dependencies=[Dependency("CUDA_Driver_jll", v"13.3.4"; compat="13.3.4 - 13"),
                                 BuildDependency(PackageSpec(name="CUDA_SDK_jll", version="10.2.89"))],
                   script=get_script(), platforms=[augmented_platform], products=get_products(platform),
                   sources=[], init_block=""
            ))
        else
            # the runtime libraries may link against libraries from CUDA_Compiler_jll with
            # major-versioned sonames (e.g. libnvJitLink), so detect the mismatched pairs
            # that can result from setting the version preference on only one of the JLLs
            # (e.g. from a LocalPreferences.toml predating the runtime/compiler split).
            init_block = """
                if isdefined(CUDA_Compiler_jll, :cuda_version)
                    let runtime = v"$(version.major).$(version.minor)",
                        compiler = Base.thisminor(CUDA_Compiler_jll.cuda_version)
                        if compiler.major != runtime.major
                            @error \"\"\"CUDA_Runtime_jll provides CUDA \$runtime, but CUDA_Compiler_jll provides CUDA \$compiler.
                                       These versions need to have the same major version; call `CUDA.set_runtime_version!` to
                                       reconfigure both, or remove stale entries from your LocalPreferences.toml.\"\"\"
                        elseif compiler < runtime
                            @warn \"\"\"CUDA_Runtime_jll provides CUDA \$runtime, which is newer than CUDA_Compiler_jll's CUDA \$compiler.
                                      This is an unsupported combination; call `CUDA.set_runtime_version!` to reconfigure both.\"\"\"
                        end
                    end
                end"""
            # CUDA_Compiler_jll is only needed at run time (see the init block above), so it
            # is not installed in the build prefix. That also means building does not require
            # a registered CUDA_Compiler_jll compatible with the CUDA_Driver_jll we depend on
            # (0.6.1 is the first version that allows CUDA_Driver_jll 13.3.4).
            push!(builds,
                (; dependencies=[Dependency("CUDA_Driver_jll", v"13.3.4"; compat="13.3.4 - 13"),
                                 RuntimeDependency("CUDA_Compiler_jll"; compat="0.6.1")],
                   script, platforms=[augmented_platform], products=get_products(platform),
                   sources=get_sources("cuda", components; version, platform=augmented_platform),
                   init_block
            ))
        end
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

# The audit is expected to complain about these vendor binaries: mixed C++ string ABIs
# (CUPTI and nvperf use cxx03, the rest cxx11), libgcc_s not being in the prefix, and
# libraries that cannot be dlopen'ed on the host because they depend on CUDA_Compiler_jll
# (libnvJitLink). None of that is fatal (`ignore_audit_errors` defaults to `true`), and
# the audit is still valuable: it adds an `$ORIGIN` RUNPATH to the few libraries that
# lack one (e.g. CUDA 10.2's libcublas, or libcusolverMg), which otherwise resolve
# their dependencies through the system loader and can pick up a local CUDA toolkit.
for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, build.products, build.dependencies;
                   julia_compat="1.10", augment_platform_block, init_block=build.init_block,
                   lazy_artifacts=true, dont_dlopen=true)
end

# bump
