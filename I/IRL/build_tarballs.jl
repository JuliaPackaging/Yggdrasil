# build_tarballs.jl — BinaryBuilder recipe for IRL_jll.
#
# Ships the Interface Reconstruction Library's C interface as `libirl_c`
# (+ its sibling `libirl`). Move this file to Yggdrasil at I/IRL/build_tarballs.jl
# and open a PR to have IRL_jll built and registered.
#
# Verified locally on x86_64-linux-gnu (GCC 12): builds libirl_c.so with abseil
# statically absorbed (no libabsl_*.so runtime deps) and passes the IRL.jl tests.

using BinaryBuilder, Pkg

name    = "IRL"
version = v"0.1.0"   # not an upstream tag — bump when re-pinning `sources`.

# Pin an exact commit: JLLs must build from an immutable source snapshot.
# 062aa76 = upstream default branch @ 2025-09-03. Ask the maintainer for a
# tagged release and switch to it when one exists.
sources = [
    GitSource("https://github.com/robert-chiodi/interface-reconstruction-library.git",
              "062aa7659a6a46e3ae13de6be8b3fa787902b8c6"),
]

# Notes baked into the script:
#  • IRL's `make install` only declares ARCHIVE (static) destinations and is
#    broken for shared libs — so we install the .so/.dylib/.dll by hand.
#  • Build abseil STATIC + PIC so it is absorbed into libirl/libirl_c, leaving
#    zero libabsl_* runtime products. (Upstream's USE_ABSL=OFF is a no-op bug and
#    its IRL_NO_ABSL path fails to compile, so we keep abseil but hide it.)
#  • `irl_c` is EXCLUDE_FROM_ALL unless IRL_BUILD_FORTRAN=ON; we build the target
#    explicitly instead, avoiding any Fortran compilation.
script = raw"""
cd $WORKSPACE/srcdir/interface-reconstruction-library

# --- force abseil to build static + PIC while IRL stays shared ---
python3 - <<'PY'
import io
f = "CMakeLists.txt"
s = open(f).read()
needle = "  add_subdirectory(${ABSEIL_DIR})"
repl = ("  set(BSL_SAVE ${BUILD_SHARED_LIBS})\n"
        "  set(BUILD_SHARED_LIBS OFF)\n"
        "  set(CMAKE_POSITION_INDEPENDENT_CODE ON)\n"
        "  add_subdirectory(${ABSEIL_DIR})\n"
        "  set(BUILD_SHARED_LIBS ${BSL_SAVE})")
assert needle in s, "abseil add_subdirectory line not found — recipe needs updating"
open(f, "w").write(s.replace(needle, repl))
print("patched abseil to static+PIC")
PY

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DEigen3_DIR=${prefix}/share/eigen3/cmake

# Build only the C interface (pulls in the irl core + abseil transitively).
cmake --build . --target irl_c -j${nproc}

# Manual install (upstream install rules don't handle shared libs).
mkdir -p ${libdir} ${includedir}
for lib in libirl libirl_c; do
    for ext in so dylib dll; do
        for f in $(find . -name "${lib}.${ext}*"); do
            install -Dvm755 "$f" "${libdir}/$(basename $f)"
        done
    done
done

# Headers (optional but useful for downstream C/C++ consumers).
cp -r ../irl ${includedir}/ 2>/dev/null || true
find ${includedir}/irl -type f ! -name '*.h' ! -name '*.tpp' -delete 2>/dev/null || true
"""

# Standard Yggdrasil platform set. C++14 + abseil is portable; if a platform
# fails CI, filter it here and note the gap rather than dropping it silently.
platforms = supported_platforms()
# riscv64-linux-gnu fails to build the C++/abseil stack (toolchain gap on this
# tier-3 platform); drop it rather than block the whole package.
platforms = filter(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)   # libstdc++ ABI matters (C++ lib)

products = [
    LibraryProduct("libirl_c", :libirl_c),
    LibraryProduct("libirl",   :libirl),
]

dependencies = [
    # Eigen is header-only and needed only at build time.
    HostBuildDependency(PackageSpec(name = "Eigen_jll")),
    BuildDependency(PackageSpec(name = "Eigen_jll")),
    # libirl/libirl_c link libgcc_s (C++ exceptions / std::string); provide it at
    # runtime so it resolves on all platforms (dry-run flagged it as unmapped).
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll")),
]

# GCC 8+ for C++14/abseil; bump if abseil requires newer.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9", julia_compat = "1.6")
