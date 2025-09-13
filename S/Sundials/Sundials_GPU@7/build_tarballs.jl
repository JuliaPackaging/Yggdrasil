include("../common.jl")
name = "Sundials_GPU"

include(normpath(joinpath(YGGDRASIL_DIR, "..", "platforms", "cuda.jl")))

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = install_script

augment_platform_block = CUDA.augment

# The products that we will ensure are always built
products = get_products()

platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "windows"),
]
platforms = expand_gfortran_versions(platforms)

for cuda_version in [v"12.0"], platform in platforms

    # For platforms we can't create cuda builds on, we want to avoid adding cuda=none
    # https://github.com/JuliaPackaging/Yggdrasil/issues/6911#issuecomment-1599350319
    augmented_platform = Platform(arch(platform), os(platform);
                                  libgfortran_version = libgfortran_version(platform),
                                  cuda=CUDA.platform(cuda_version)
    )
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = get_dependencies(augmented_platform; cuda = true, cuda_version = cuda_version)
    
    build_tarballs(ARGS, name, ygg_version, sources,  script, [augmented_platform], products, dependencies;
                   preferred_gcc_version=v"9",
                   julia_compat="1.6",
                   augment_platform_block)

end
