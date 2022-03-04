# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "RadeonProRender"
version = v"2.2.9"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GPUOpen-LibrariesAndSDKs/RadeonProRenderSDK.git", "5916c58f9cc037899e0aa85e5f5a67c6e1ee7b29")
]

# TODO, also ship headers for Clang.jl generation!?
script = raw"""
echo ${target}
cd $WORKSPACE/srcdir/RadeonProRenderSDK/RadeonProRender
if [[ ${target} == x86_64-linux-gnu ]]; then
    cp binUbuntu18/* ${libdir}/
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    cp binMacOS/* ${libdir}/
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cp binWin64/* ${libdir}/
fi
"""

# TODO, can we add centos7?
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows")
]

# Fix warning in BinaryBuilder:
platforms = expand_cxxstring_abis(platforms)

# TODO, Hybrid doesn't exist on OSX, so I guess we can't include it?!
products = [
    # LibraryProduct("Hybrid", :Hybrid),
    # LibraryProduct("HybridPro", :HybridPro),

    # I don't think we need the executables:
    # BinaryProduct("RprTextureCompiler64", :RprTextureCompiler64),
    # BinaryProduct("RprsRender64", :RprsRender64),
    LibraryProduct(["Northstar64", "libNorthstar64"], :libNorthstar64),
    LibraryProduct(["ProRenderGLTF", "libProRenderGLTF"], :libProRenderGLTF),
    LibraryProduct(["RadeonProRender64", "libRadeonProRender64"], :libRadeonProRender64),
    LibraryProduct(["RprLoadStore64", "libRprLoadStore64"], :libRprLoadStore64),
    LibraryProduct(["Tahoe64", "libTahoe64"], :libTahoe64),
]

# Dependencies that must be installed before this package can be built
dependencies = [

    # Not really needed for repacking, but if we ever want to
    # build from scratch we'll need at least these:

    # HostBuildDependency("GLEW_jll"),
    # HostBuildDependency("GLU_jll"),
    # HostBuildDependency("Lua_jll"),
    # BuildDependency("Vulkan_Headers_jll"),
    # BuildDependency("OpenCL_Headers_jll"),
    # BuildDependency("ROCmDeviceLibs_jll"),
    # BuildDependency("ROCmOpenCLRuntime_jll"),
    # BuildDependency("ROCmCompilerSupport_jll"),

    # fix warning from BinaryBuilder:
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
