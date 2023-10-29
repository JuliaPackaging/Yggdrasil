# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GenICamRuntime"
version = v"3.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.emva.org/wp-content/uploads/GenICam_V3_1_0_public_data.zip", "4c551e9a09cab1a5224350698249ea7f81f473e6a76b755fe792e11d30c66f2e"; unpack_target = "GenICam")
]

# Bash recipe for building across all platforms
script = raw"""
target_arch_os=$(echo $target | cut -d- -f1-2)
declare -A genicam_target_map=(
    ["arm-linux"]="Linux32_ARMhf"
    ["i686-linux"]="Linux32_i86"
    ["aarch64-linux"]="Linux64_ARM"
    ["x86_64-linux"]="Linux64_x64"
    ["x86_64-apple"]="Maci64_x64"
    ["i686-w64"]="Win32_i86"
    ["x86_64-w64"]="Win64_x64"
)
genicam_arch_os=${genicam_target_map[$target_arch_os]}
echo $genicam_arch_os

cd $WORKSPACE/srcdir
cd GenICam
if [[ $target == *w64-mingw32 ]]; then
    unzip GenICam_V*-${genicam_arch_os}_*-Runtime.zip
else
    tar xfz GenICam_Runtime_*_${genicam_arch_os}_v*.tgz 
fi
ls -laR
mkdir -p $libdir
for F in bin/${genicam_arch_os}/*.$dlext; do
    install -v -D -m 755 $F $libdir/`basename $F`
done
mkdir -p $libdir/genicam
cp -av log $libdir/genicam/
install_license License_ReadMe.txt
cp -av licenses/GenICam_License_20140921.pdf $prefix/share/licenses/GenICamRuntime/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "powerpc64le" , platforms)
filter!(p -> !(arch(p) == "aarch64" && os(p) == "macos") , platforms)
filter!(p -> os(p) != "freebsd" , platforms)

# The products that we will ensure are always built
toolchains = ["gcc48", "gcc46", "gcc42", "clang61"]
expand_library_name(n) = vcat(
    ["lib$(n)_$(toolchain)_v$(version.major)_$(version.minor)" for toolchain in toolchains],
    "$(n)_MD_VC120_v$(version.major)_$(version.minor)",
)
products = [
    LibraryProduct(expand_library_name("GCBase"), :libGCBase),
    LibraryProduct(expand_library_name("GenApi"), :libGenApi),
    LibraryProduct(expand_library_name("Log"), :libLog),
    LibraryProduct(expand_library_name("MathParser"), :libMathParser),
    LibraryProduct(expand_library_name("NodeMapData"), :libNodeMapData),
    LibraryProduct(expand_library_name("XmlParser"), :libXmlParser),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
