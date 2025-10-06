# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ProGraphMSA"
version = v"2020.09.29"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/acg-team/ProGraphMSA.git", "51cf68a58f2e8900b3cfb40d24d335f7405abbed"),
    ArchiveSource("https://sourceforge.net/projects/tclap/files/tclap-1.2.2.tar.gz", "f5013be7fcaafc69ba0ce2d1710f693f61e9c336b6292ae4f57554f59fde5837"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
##########
# 0) Environment
##########
ROOT="${WORKSPACE}/srcdir"
PG_DIR="${ROOT}/ProGraphMSA"
TCLAP_DIR="${ROOT}/tclap-1.2.2"

# Disable Eigen vectorization/asserts for portability
COMMON_EIGEN_DEFS="-DEIGEN_DONT_VECTORIZE -DEIGEN_DISABLE_UNALIGNED_ARRAY_ASSERT"

# Prefer Ninja if available
GEN="Unix Makefiles"
command -v ninja >/dev/null 2>&1 && GEN="Ninja"

##########
# 1) Install TCLAP (header-only)
##########
mkdir -p "${prefix}/include/tclap"
cp -av "${TCLAP_DIR}/include/tclap/"*.h "${prefix}/include/tclap/"

##########
# 2) Patch ProGraphMSA sources (Linux portability only)
##########
pushd "${PG_DIR}"

# Strip problematic flags if present (SSE on non-x86, unsafe fast-math)
for f in CMakeLists.txt src/CMakeLists.txt; do
  if [ -f "$f" ]; then
    sed -i -E 's/[[:space:]]*-msse2[[:space:]]*/ /g' "$f" || true
    sed -i -E 's/[[:space:]]*-ffast-math[[:space:]]*/ /g' "$f" || true
  fi
done

# Provide std::char_traits specializations so libc++ can handle custom alphabets.
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/char_traits.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix_codon_table.patch"

popd

##########
# 3) Configure & build
##########
pushd "${PG_DIR}"

# Eigen headers: typically provided by Eigen_jll at ${prefix}/include/eigen3
EXTRA_INC="-I${prefix}/include -I${prefix}/include/eigen3"

if [[ "${target}" == *-apple-darwin* ]]; then
  sed -i "s/${target}-clang++/${target}-g++/g" "${CMAKE_TARGET_TOOLCHAIN}"
  sed -i "s/${target}-gcc++/${target}-g++/g" "${CMAKE_TARGET_TOOLCHAIN}"
  sed -i "s/${target}-clang/${target}-gcc/g" "${CMAKE_TARGET_TOOLCHAIN}"
  sed -i "s/${target}-gccclang/${target}-gcc/g" "${CMAKE_TARGET_TOOLCHAIN}"
fi

rm -rf build
cmake_extra=()
if [[ "${target}" == *-apple-darwin* ]]; then
  cmake_extra+=(
    -DCMAKE_C_COMPILER="${target}-gcc"
    -DCMAKE_CXX_COMPILER="${target}-g++"
  )
fi

cmake -S . -B build -G "${GEN}" \
  -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=11 \
  -DCMAKE_CXX_EXTENSIONS=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DWITH_SSE=OFF \
  -DCMAKE_CXX_FLAGS="${EXTRA_INC} ${COMMON_EIGEN_DEFS}" \
  ${cmake_extra[@]}

cmake --build build --parallel "${nproc}"

cmake --install build

install_license ./LICENSE

popd
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Only build for Linux and macOS
platforms = supported_platforms()
platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ProGraphMSA", :ProGraphMSA)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version = v"13.0.1")
