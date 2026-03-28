# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "Mesa"
version = v"26.0.3"
llvm_version = v"18.1.7+5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mesa3d.org/mesa-$version.tar.xz",
                  "ddb7443d328e89aa45b4b6b80f077bf937f099daeca8ba48cabe32aab769e134"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mesa-*

apk add py3-mako py3-yaml py3-packaging

# Enable llvmpipe where LLVM is available, fall back to softpipe
if [ -d "${prefix}/lib/cmake/llvm" ]; then
    GALLIUM_DRIVERS="softpipe,llvmpipe"
    LLVM_FLAGS="-D llvm=enabled -D shared-llvm=enabled -D cpp_rtti=false"
    # Tell meson where to find llvm-config for cross compilation
    sed -i "/^\[binaries\]/a llvm-config = '${prefix}/tools/llvm-config'" ${MESON_TARGET_TOOLCHAIN}
else
    GALLIUM_DRIVERS="softpipe"
    LLVM_FLAGS="-D llvm=disabled"
fi

MESA_FLAGS=(
    -D b_ndebug=true
    -D buildtype=release
    -D strip=true
    ${LLVM_FLAGS}
    -D gallium-drivers=${GALLIUM_DRIVERS}
    -D vulkan-drivers=[]
    -D gles1=disabled
    -D gles2=disabled
    -D shader-cache=disabled
)

if [[ "${target}" == *-mingw* ]]; then
    MESA_FLAGS+=(
        -D platforms=windows
        -D glx=disabled
        -D egl=disabled
        -D gbm=disabled
    )
elif [[ "${target}" == *-linux* ]] || [[ "${target}" == *-freebsd* ]]; then
    MESA_FLAGS+=(
        -D platforms=x11
        -D glx=xlib
        -D egl=disabled
        -D gbm=disabled
    )
fi

meson setup build "${MESA_FLAGS[@]}" --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -C build -j${nproc}
ninja -C build install

if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/bin/opengl32.dll ${prefix}/bin/opengl32sw.dll
fi

install_license docs/license.rst
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# macOS provides OpenGL natively; Mesa doesn't produce a GL library without X11/GLX
filter!(p -> !Sys.isapple(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["opengl32sw", "libGL"], :libmesaGL),
]

# Platform augmentation for LLVM version matching
augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# X11 dependencies needed on Linux/FreeBSD
x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Build for both assert and non-assert LLVM variants
builds = []
for llvm_assertions in (false, true)
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"

    dependencies = [
        Dependency("CompilerSupportLibraries_jll"),
        Dependency("Zlib_jll"; compat="1.2.12"),
        Dependency("Expat_jll"; platforms=x11_platforms),
        Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
        Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
        Dependency("Xorg_libxcb_jll"; platforms=x11_platforms),
        Dependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
        Dependency("Xorg_libxshmfence_jll"; platforms=x11_platforms),
        Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
        Dependency("Xorg_libXxf86vm_jll"; platforms=x11_platforms),
        # LLVM for llvmpipe: shared library at runtime, full package at build time
        Dependency("libLLVM_jll"),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, products,
            sources,
            platforms=[augmented_platform],
            script,
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, build.script,
        build.platforms, build.products, build.dependencies;
        julia_compat="1.6", preferred_gcc_version=v"10", clang_use_lld=false,
        augment_platform_block, lazy_artifacts=true)
end
