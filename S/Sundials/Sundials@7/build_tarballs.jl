include("../common.jl")

name = "Sundials"

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = install_script

# The products that we will ensure are always built
products = get_products()

platforms = get_platforms()

for platform in platforms
    
    should_build_platform(triplet(platform)) || continue

    dependencies = get_dependencies(platform)

    build_tarballs(ARGS, name, ygg_version, sources,  script, [platform], products, dependencies;
                   preferred_gcc_version=v"6",
                   julia_compat="1.6")
end
