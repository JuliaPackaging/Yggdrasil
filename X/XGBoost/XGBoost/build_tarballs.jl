include("../common.jl")

name = "XGBoost"
version = v"2.1.5"

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
make -j${nproc}
cd ..
""" * install_script

# The products that we will ensure are always built
products = get_products()

platforms = get_platforms()

for platform in platforms
    
    should_build_platform(triplet(platform)) || continue

    dependencies = get_dependencies(platform)

    build_tarballs(ARGS, name, version, sources,  script, [platform], products, dependencies;
                    preferred_gcc_version=v"9",
                    julia_compat="1.6")
end