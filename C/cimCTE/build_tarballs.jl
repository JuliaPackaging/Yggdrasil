# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cimCTE"
version = v"1.0.0"

# Sources required to build cimCTE
sources = [
    GitSource("https://github.com/cimgui/cimCTE.git",
              "dbf2abe4841b9dd8a3f1f1864038ac9d60155c5e"),

    # Clone the cimgui version CImGuiPack_jll is built with
    GitSource("https://github.com/cimgui/cimgui.git",
              "5d7cc7e12de9a868bbecc00ce2ed74e58d266f1c"),

    # Bundled CMakeLists.txt that links against CImGuiPack_jll's exported
    # cimgui::cimgui target rather than rebuilding imgui sources locally
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms.
script = raw"""
cd $WORKSPACE/srcdir
git -C cimCTE submodule update --init --recursive --depth 1

cd $WORKSPACE/srcdir

# Regenerate cimCTE with comments
cd cimCTE/generator
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
install -Dvm 644 ../cimCTE/generator/output/*.json -t ${prefix}/share/cimCTE

install_license ../cimCTE/ImGuiColorTextEdit/LICENSE
"""

# Match CImGuiPack's platform filter
platforms = filter(p -> arch(p) ∉ ("armv6l", "riscv64") &&
                        !(arch(p) == "aarch64" && os(p) == "freebsd"),
                   supported_platforms())

# The auditor says we need this because std::string is used in the library
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimCTE", :libcimCTE),
    FileProduct("share/cimCTE/definitions.json",       :cimCTE_definitions),
    FileProduct("share/cimCTE/structs_and_enums.json", :cimCTE_structs_and_enums),
    FileProduct("share/cimCTE/typedefs_dict.json",     :cimCTE_typedefs_dict),
    FileProduct("share/cimCTE/constants.json",         :cimCTE_constants),
]

dependencies = [
    Dependency("CImGuiPack_jll"; compat="0.14"),
    HostBuildDependency("LuaJIT_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")
