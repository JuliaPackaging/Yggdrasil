# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "ClangExtract"
version = v"0.1.0"

# Collection of sources required to build ClangExtract
sources = [
    GitSource("https://github.com/SUSE/clang-extract.git", "5da361949c64396943b2911ed1867a0e2734d1e4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/clang-extract

# Apply patches from bundled/patches/
#for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
#    atomic_patch -p1 "${patch}"
#done

# Fix destructor syntax issues
# 1. Remove (void) from destructor declaration and definition
sed -i 's/~ElfObject(void)/~ElfObject()/g' libcextract/ElfCXX.hh
sed -i 's/~ElfObject(void)/~ElfObject()/g' libcextract/ElfCXX.cpp
# 2. Fix explicit destructor calls to use this->
sed -i 's/ElfObject::~ElfObject();/this->~ElfObject();/g' libcextract/ElfCXX.cpp

# Find all C++ source files
MAIN_SOURCES="Main.cpp"
INLINE_SOURCES="Inline.cpp"
LIB_SOURCES=$(find libcextract -name "*.cpp" | tr '\n' ' ')

# Set up compiler flags - use c++2a for GCC 9 C++20 support
export CXXFLAGS="-std=c++2a -O3 -fPIC"
export CXXFLAGS="${CXXFLAGS} -I${prefix}/include"
export CXXFLAGS="${CXXFLAGS} -Ilibcextract"
export CXXFLAGS="${CXXFLAGS} -D_GNU_SOURCE"
export CXXFLAGS="${CXXFLAGS} -DLLVM_VERSION_MAJOR=20"

# Set up linker flags
export LDFLAGS="-L${prefix}/lib -L${libdir}"
export LDFLAGS="${LDFLAGS} -lclang-cpp -lLLVM"
export LDFLAGS="${LDFLAGS} -lelf -lz -lzstd"
export LDFLAGS="${LDFLAGS} -lpthread -ldl"

# Use g++ from the target toolchain
export CXX="g++"

echo "Building libcextract static library..."
echo $nproc
# First compile all library sources into object files
mkdir -p build_objs
for src in ${LIB_SOURCES}; do
    obj_file="build_objs/$(basename ${src%.cpp}.o)"
    echo "Compiling $src -> $obj_file"
    ${CXX} ${CXXFLAGS} -c $src -o $obj_file &
    ((i=i%nproc)) || true; ((i++==0)) && wait
done
wait

# Create static library
echo "Creating static library..."
ar rcs libcextract.a build_objs/*.o

# Build clang-extract executable
echo "Building clang-extract..."
${CXX} ${CXXFLAGS} ${MAIN_SOURCES} -Wl,--start-group libcextract.a ${LDFLAGS} -Wl,--end-group -o clang-extract

# Build ce-inline executable
echo "Building ce-inline..."
${CXX} ${CXXFLAGS} ${INLINE_SOURCES} -Wl,--start-group libcextract.a ${LDFLAGS} -Wl,--end-group -o ce-inline

# Install binaries
install -Dm755 clang-extract ${bindir}/clang-extract
install -Dm755 ce-inline ${bindir}/ce-inline

# Install license
install_license LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Only build for platforms where we have LLVM_full_jll available
# LLVM_full_jll doesn't have i686-linux-musl binaries
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl" && arch(p) == "i686"), platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# We don't have ElfUtils for this
filter!(p -> !Sys.iswindows(p), platforms)

platforms = expand_cxxstring_abis(platforms)
filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("clang-extract", :clang_extract),
    ExecutableProduct("ce-inline", :ce_inline),
]

llvm_versions = [v"20.1.8+0"]

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        Dependency("Elfutils_jll"),
        Dependency("Zlib_jll"),
        Dependency("Zstd_jll"),
        # LLVM jlls are complicated - sigh - don't ask
        RuntimeDependency("Clang_jll"),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]
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

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
                   preferred_gcc_version=v"9", julia_compat="1.6",
                   augment_platform_block)
end
