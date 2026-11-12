include("../common.jl")

name = "XGBoost"
version = v"2.1.5"

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = raw"""
# apple builds require a newer SDK (at least v12 to cover both x86_64 and aarch64) based on build info here:
# https://github.com/dmlc/xgboost/blob/910c34b971b06861e66d3850714540b0697001e1/ops/pipeline/build-python-wheels-macos.sh#L14-L24
if [[ $target == *"apple-darwin"* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=12
fi

# remove default cmake to use newer version from build dependency
apk del cmake

# now build library
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
make -j${nproc}

# move out of the build folder - the install script runs at the level of the xgboost directory
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