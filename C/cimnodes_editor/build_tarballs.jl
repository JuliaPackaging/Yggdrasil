# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cimnodes_editor"
version = v"0.9.3"

# Sources required to build cimnodes_editor
sources = [
    GitSource("https://github.com/cimgui/cimnodes_editor.git",
              "552cc280792e3cde4d7012ff31b4c85cf083ada8"),

    # Clone the cimgui version CImGuiPack_jll is built with
    GitSource("https://github.com/cimgui/cimgui.git",
              "1261b231939fc210032f30c4ee8a8f0440372237"),

    # Bundled CMakeLists.txt that links against CImGuiPack_jll's exported
    # cimgui::cimgui target rather than rebuilding imgui sources locally.
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms.
script = raw"""
cd $WORKSPACE/srcdir
git -C cimnodes_editor submodule update --init --recursive --depth 1

# Regenerate cimnodes_editor with comments
cd cimnodes_editor/generator
sed -i "s|g++ \"\$TARGETS\"|${HOSTCC} \"\$TARGETS\"|" generator.sh
bash ./generator.sh -t comments
cd $WORKSPACE/srcdir

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_PREFIX_PATH=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

# Copy generator files
install -Dvm 644 ../cimnodes_editor/generator/output/*.json -t ${prefix}/share/cimnodes_editor

install_license ../cimnodes_editor/imgui-node-editor/LICENSE
"""

# Match CImGuiPack's platform filter
platforms = filter(p -> arch(p) ∉ ("armv6l", "riscv64") &&
                        !(arch(p) == "aarch64" && os(p) == "freebsd"),
                   supported_platforms())

# The auditor says we need this because std::string is used in the library
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimnodes_editor", :libcimnodes_editor),
    FileProduct("share/cimnodes_editor/definitions.json",       :cimnodes_editor_definitions),
    FileProduct("share/cimnodes_editor/structs_and_enums.json", :cimnodes_editor_structs_and_enums),
    FileProduct("share/cimnodes_editor/typedefs_dict.json",     :cimnodes_editor_typedefs_dict),
    FileProduct("share/cimnodes_editor/constants.json",         :cimnodes_editor_constants),
]

dependencies = [
    Dependency("CImGuiPack_jll"; compat="0.12.2"),
    HostBuildDependency("LuaJIT_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"5")
