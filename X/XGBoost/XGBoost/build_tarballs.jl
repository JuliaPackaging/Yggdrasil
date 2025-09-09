using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "XGBoost"
version = v"2.1.4"

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

# Collection of sources required to build XGBoost
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","62e7923619352c4079b24303b367134486b1c84f"), # v2.1.4
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

# https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/193
# error: 'any_cast<std::shared_ptr<xgboost::data::CSRArrayAdapter>>' 
# is unavailable: introduced in macOS 10.14
# `std::filesystem` support was introduced in macOS 10.15
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

# builds on MacOS seem to fail with Clang - use gcc instead
# see https://github.com/dmlc/xgboost/issues/11676
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake"
make -j${nproc}

# Manual installation, to avoid installing dmlc
cd ..
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
# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
]

platforms = expand_cxxstring_abis(supported_platforms())

for platform in platforms
    
    should_build_platform(triplet(platform)) || continue

    dependencies = AbstractDependency[
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); 
            platforms=filter(!Sys.isbsd, [platform])),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); 
            platforms=filter(Sys.isbsd, [platform])),
    ]

    build_tarballs(ARGS, name, version, sources,  script, [platform], products, dependencies;
                    preferred_gcc_version=v"9",
                    julia_compat="1.6")
end