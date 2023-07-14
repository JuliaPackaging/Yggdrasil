# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GLScopeClient"
version = v"0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/glscopeclient/scopehal-apps.git",
              "8bbb0fe835b23620f659472a1f60079792e4f529"),
    GitSource("https://github.com/glscopeclient/scopehal.git",
              "617377bd0b5ff2ba4457d604212f5c17fe500b01"), # -> scopehal-apps/lib
    GitSource("https://github.com/glscopeclient/VkFFT.git",
              "1f07db3791e810a71296e63683c09412784111eb"), # -> scopehal-apps/lib/VkFFT
    GitSource("https://github.com/glscopeclient/graphwidget.git",
              "512b84a20f11c47b4dd4e0971980b193016d452b"), # -> scopehal-apps/lib/graphwidget
    GitSource("https://github.com/glscopeclient/logtools.git",
              "3f599e5727be78a6a074e49d72f352dfb0b86af3"), # -> scopehal-apps/lib/log
    GitSource("https://github.com/glscopeclient/xptools.git",
              "fb8f8e0b226d98180a85fb518e40e46d688f50b1"), # -> scopehal-apps/lib/xptools
    GitSource("https://github.com/glscopeclient/scopehal-docs.git",
              "bdf8f89ae93d30499d2744fb68ab6f6ecd21e1de"), # -> scopehal-apps/doc
    GitSource("https://github.com/ocornut/imgui",
              "031148dc56d70158b3ad84d9be95b04bb3f5baaf"), # -> scopehal-apps/src/imgui
    GitSource("https://github.com/glscopeclient/implot.git",
              "6035ea0f9d4e8b5265a690cf33c4551999765079"), # -> scopehal-apps/src/implot
    GitSource("https://github.com/glscopeclient/imgui-node-editor.git",
              "67e85c2e128ae0a2ef9995948739bb42c640e4e6"), # -> scopehal-apps/src/imgui-node-editor
    GitSource("https://github.com/aiekick/ImGuiFileDialog.git",
              "2917cd9ec120bce7b4297e7f3afb660071707e05"), # -> scopehal-apps/src/ImGuiFileDialog
    GitSource("https://github.com/btzy/nativefiledialog-extended.git",
              "06a5c1f0ad98637a45acb3faa4a331600dd2cdc3"), # -> scopehal-apps/src/nativefiledialog-extended
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

# Start by moving things into the proper places
declare -A destdir=(
  [scopehal]=lib
  [VkFFT]=lib/VkFFT
  [graphwidget]=lib/graphwidget
  [logtools]=lib/log
  [xptools]=lib/xptools
  [imgui]=src/imgui
  [implot]=src/implot
  [imgui-node-editor]=src/imgui-node-editor
  [ImGuiFileDialog]=src/ImGuiFileDialog
  [nativefiledialog-extended]=src/nativefiledialog-extended
  [scopehal-docs]=doc
)

# XXX: Some of these destinations overlap, so order matters
for submodule in scopehal VkFFT graphwidget logtools xptools scopehal-docs \
                 imgui implot imgui-node-editor ImGuiFileDialog nativefiledialog-extended; do
    rm -rf "${WORKSPACE}/srcdir/scopehal-apps/${destdir[$submodule]}"
    mv "${WORKSPACE}/srcdir/${submodule}" "${WORKSPACE}/srcdir/scopehal-apps/${destdir[$submodule]}"
done

cd $WORKSPACE/srcdir/scopehal-apps/
atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-fix-glslang-includes.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/0002-define-aligned-alloc.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/0003-missing-librt.patch

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=NO \
    ..
make -j${nproc}
make install

install_license $WORKSPACE/srcdir/scopehal-apps/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# Only x86-64 is officially supported for now
platforms = filter!(p -> arch(p) == "x86_64", supported_platforms())
platforms = expand_cxxstring_abis(platforms; skip=Returns(false))

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libscopehal", :libscopehal)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Vulkan_Headers_jll"),
    Dependency("Vulkan_Loader_jll"),
    Dependency("glslang_jll"),
    Dependency("Shaderc_jll"),
    Dependency("ffts_jll"),
    Dependency("yaml_cpp_jll"),
    Dependency("GLEW_jll"),
    Dependency("GTKmm3_jll"),
    Dependency("libsigcpp_jll"; compat="^2.12.0"),
    Dependency("GLU_jll"; platforms=x11_platforms),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("GLFW_jll"),
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10")
