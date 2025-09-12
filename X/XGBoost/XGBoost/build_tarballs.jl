include("../common.jl")

name = "XGBoost"
version = v"2.1.4+0"

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/

# we can't seem to build from source for Apple, so install the pre-built binaries directly instead
# see https://github.com/dmlc/xgboost/issues/11676 for details
if [[ "${target}" == *apple-darwin* ]]; then
    unzip -d xgboost-${target} xgboost-${target}.whl
    cd xgboost-${target}/xgboost
    cp ../../xgboost/LICENSE .
else
    cd xgboost
    git submodule update --init
    mkdir build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    make -j${nproc}
    cd ..
fi
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