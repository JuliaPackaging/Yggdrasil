# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Tools"
version = v"6.8.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = true

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qttools-everywhere-src-$version.tar.xz",
                  "326381b7d43f07913612f291abc298ae79bd95382e2233abce982cff2b53d2c0"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.1.tar.bz2",
                  "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qttools-*`

rm /usr/lib/libexpat.so.1

if [[ "${target}" == *apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=12
fi

case "$bb_full_target" in

    x86_64-linux-musl*)
        cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *mingw*)
        cd $WORKSPACE/srcdir/mingw*/mingw-w64-headers
        ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
        make install

        cd ../mingw-w64-crt/
        if [ ${target} == "i686-w64-mingw32" ]; then
            _crt_configure_args="--disable-lib64 --enable-lib32"
        elif [ ${target} == "x86_64-w64-mingw32" ]; then
            _crt_configure_args="--disable-lib32 --enable-lib64"
        fi
        ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
        make -j${nproc}
        make install

        cd ../mingw-w64-libraries/winpthreads
        ./configure --prefix=/opt/$target/$target/sys-root --host=$target --enable-static --enable-shared
        make -j${nproc}
        make install

        cd $WORKSPACE/srcdir/build
        cmake -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *)
        cmake -G Ninja -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

# Get the common Qt/LLVM platforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "Q", "Qt6Base", "common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("assistant", :assistant),
    ExecutableProduct("designer", :designer),
    ExecutableProduct("linguist", :linguist),
    ExecutableProduct("pixeltool", :pixeltool),
    ExecutableProduct("qdbus", :qdbus),
    ExecutableProduct("qdbusviewer", :qdbusviewer),
    ExecutableProduct("qdistancefieldgenerator", :qdistancefieldgenerator),
    ExecutableProduct("qdoc", :qdoc),
    ExecutableProduct("qtdiag", :qtdiag),
    ExecutableProduct("qtplugininfo", :qtplugininfo)
]

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
llvm_versions = [v"20.1.8+0"]
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        HostBuildDependency("Qt6Base_jll"),
        Dependency("Expat_jll"; compat="2.6.5"),
        Dependency("Qt6Base_jll"; compat="="*string(version)),
        Dependency("Qt6Declarative_jll"; compat="="*string(version)),
        BuildDependency("Vulkan_Headers_jll"),
        # LLVM jlls are complicated - sigh - don't ask
        RuntimeDependency("Clang_jll"),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]
    if !host_build
        push!(dependencies, HostBuildDependency("Qt6LinguistTools_jll"))
    end

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            platforms=[augmented_platform],
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

# Can't use build_qt here because we need finer control over the LLVM version
for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
                   preferred_gcc_version=any(Sys.isapple, build.platforms) ? nothing :
                                         any(Sys.iswindows, build.platforms) ? v"13" : v"10", julia_compat="1.6",
                   preferred_llvm_version=qt_llvm_version,
                   augment_platform_block)
end
