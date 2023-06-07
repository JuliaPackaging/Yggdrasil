using BinaryBuilder, Pkg

name = "Foldseek"
version = v"6"

# url = "https://github.com/steineggerlab/foldseek"
# description = "Fast and sensitive comparisons of large protein structure sets"

sources = [
    # Foldseek 6-29e2557
    GitSource("https://github.com/steineggerlab/foldseek",
              "29e2557970c39c8e689601ecaae2279fff4faa17"),
    DirectorySource("./bundled"),
]

# TODO
# - use Zstd_jll ? (static lib?) (now uses builtin zstd lib)

# Build fails
# - x86_64-freebsd
#   compilation error, seems like a clash between KASSERT macro defined in lib/kerasify/keras_model.h
#   and usage in freebsd headers, e.g. at line 190 of
#   /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root//usr/include/sys/time.h
#   see: https://github.com/JuliaPackaging/Yggdrasil/pull/6195#issuecomment-1416227398

script = raw"""
cd $WORKSPACE/srcdir/foldseek*/

# patch lib/mmseqs/CMakeLists.txt so it doesn't set -march unnecessarily on ARM
atomic_patch -p1 ../patches/mmseqs-arm-simd-march-cmakefile.patch

# remove rustup check in corrosion's FindRust.cmake
atomic_patch -p1 ../patches/corrosion-remove-rustup-check.patch

ARCH_FLAGS=
if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    ARCH_FLAGS="-DHAVE_SSE2=1 -DHAVE_SSE4_1=1 -DHAVE_AVX2=1"
elif [[ "${target}" == powerpc64le-* ]]; then
    ARCH_FLAGS="-DHAVE_POWER8=1 -DHAVE_POWER9=1"
elif [[ "${target}" == aarch64-* ]]; then
    ARCH_FLAGS="-DHAVE_ARM8=1"
fi

# hack around corrosion (cmake cargo interop package) using a wrong
# target string when cross-compiling
CARGO_TARGET=
if [[ "${target}" == *-linux-* ]]; then
    # cargo uses an extra 'unknown' in the target string,
    # e.g. 'x86_64-linux-gnu' becomes 'x86_64-unknown-linux-gnu' in cargo
    CARGO_TARGET=$(echo ${target} | cut -d- -f1)-unknown-$(echo ${target} | cut -d- -f2-)
else
    CARGO_TARGET=${target}
fi

export RUSTFLAGS=
if [[ "${target}" == *-musl* ]]; then
    # avoid 'cannot create cdylib' error on musl targets
    # see https://github.com/rust-lang/cargo/issues/8607
    #     https://github.com/rust-lang/rust/issues/59302
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=RELEASE \
    -DNATIVE_ARCH=0 ${ARCH_FLAGS} \
    -DRust_COMPILER=$(which ${RUSTC}) -DRust_CARGO_TARGET=${CARGO_TARGET}
make -j${nproc}
make install

install_license ../LICENSE.md
"""

platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || Sys.isfreebsd(p) || nbits(p) == 32)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("foldseek", :foldseek)
]

dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="Bzip2_jll")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8", compilers=[:c, :rust])
