# BinaryBuilder recipe for MiraDAC_jll: the C API library libmiradac_c of MiraDAC
# (https://github.com/zhanghe9704/MiraDAC; its copy of this recipe is julia/binarybuilder/).
using BinaryBuilder, Pkg

name = "MiraDAC"
version = v"1.1.3"

# The SymEngine commit of cmake/symengine_pin.txt at the MiraDAC commit below; the build script
# checks it against that file. A GitSource, not the pin's tarball: BinaryBuilder rejects
# GitHub's automatic archives (their checksums are not guaranteed stable).
symengine_commit = "153b7e98f310bccaae586dab6b49284ccd5f4174"

sources = [
    GitSource("https://github.com/zhanghe9704/MiraDAC.git",
              "4da1849c923b6639027b2fccf3d4d3e201e4bb30"),  # tag v1.1.3
    GitSource("https://github.com/symengine/symengine.git", symengine_commit),
]

script = "SOURCE_COMMIT=$(symengine_commit)\n" * raw"""
cd ${WORKSPACE}/srcdir
PIN=MiraDAC/cmake/symengine_pin.txt
COMMIT=$(sed -n 's/^SYMENGINE_COMMIT=//p' ${PIN})
VERSION=$(sed -n 's/^SYMENGINE_VERSION=//p' ${PIN})
[ "${SOURCE_COMMIT}" = "${COMMIT}" ] || { echo "SymEngine source ${SOURCE_COMMIT} is not the pinned commit ${COMMIT}"; exit 1; }

# 1. The pinned SymEngine, static and PIC, in a private prefix (not ${prefix}): libmiradac_c
#    links it in and exports none of its symbols, so it cannot clash with SymEngine_jll.
#    The options are the pin's, except BUILD_SHARED_LIBS.
SE=${WORKSPACE}/srcdir/symengine-static
OPTS=()
STAMP_OPTS=()
while IFS='=' read -r key value; do
    case "${key}" in ''|\#*|SYMENGINE_*) continue ;; esac
    [ "${key}" = BUILD_SHARED_LIBS ] && value=OFF
    OPTS+=("-D${key}=${value}")
    STAMP_OPTS+=("${key}=${value}")
done < ${PIN}
cmake -S symengine -B build-symengine -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${SE} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF \
    "${OPTS[@]}"
cmake --build build-symengine --parallel ${nproc}
# The BinaryBuilder toolchain file forces CMAKE_INSTALL_PREFIX to ${prefix}; --prefix overrides it.
cmake --install build-symengine --prefix ${SE}

# The pin check's stamp, stating the build truthfully: it differs from the pin only in
# BUILD_SHARED_LIBS=OFF, so the check cannot pass and DA_IGNORE_SYMENGINE_PIN=ON turns its
# error into a warning (which should name only BUILD_SHARED_LIBS). That is safe here: the
# commit is the pinned one (checked above), and this library never talks to symengine.py.
mkdir -p ${SE}/share/symengine
{
    echo "SYMENGINE_COMMIT=${COMMIT}"
    echo "SYMENGINE_VERSION=${VERSION}"
    printf '%s\n' "${STAMP_OPTS[@]}"
} > ${SE}/share/symengine/miradac-pin.txt

# 2. libmiradac_c only (the other targets are not installed). SymEngine installs its
#    CMake package to <prefix>/CMake on Windows and <prefix>/lib/cmake/symengine elsewhere
#    (SymEngine's own INSTALL_CMAKE_DIR), so the hint follows the target.
case "${target}" in
    *-mingw32) SE_CMAKE_DIR=${SE}/CMake ;;
    *)         SE_CMAKE_DIR=${SE}/lib/cmake/symengine ;;
esac
cmake -S MiraDAC -B build-miradac -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DDA_BUILD_CAPI=ON -DDA_BUILD_TESTS=OFF -DDA_BUILD_EXAMPLES=OFF \
    -DWITH_SYMBOLIC=ON -DDA_IGNORE_SYMENGINE_PIN=ON \
    -DSymEngine_DIR=${SE_CMAKE_DIR} \
    -DCMAKE_SKIP_BUILD_RPATH=ON  # the build-tree binary is shipped; the audit sets its RPATH
cmake --build build-miradac --target miradac_c --parallel ${nproc}

install -Dvm 755 build-miradac/capi/libmiradac_c.${dlext} ${libdir}/libmiradac_c.${dlext}
install -Dvm 644 MiraDAC/capi/include/miradac.h ${includedir}/miradac.h
install_license MiraDAC/LICENSE

# Only mdac_* (plus toolchain symbols such as _init/_fini) may be exported. The check is
# per-object format: -D is ELF-only and cctools nm (the darwin one) has no --defined-only,
# while -gU (external, defined) works there; Mach-O symbols also carry a leading underscore.
# PE DLLs have no dynamic symbol table (nm -D reports "no symbols"); objdump -p reads the
# export table — the names are the "[   N] name" lines under the [Ordinal/Name Pointer]
# Table heading (the 32-bit objdump omits the "+base[...]" the 64-bit one shows), and the
# section ends at the next column-0 heading, before the relocations, whose lines also
# carry bracketed numbers.
if [ "${dlext}" = "dylib" ]; then
    LEAK=$(nm -gU ${libdir}/libmiradac_c.${dlext} | awk '{print $NF}' \
           | grep -v -E '^_mdac_' || true)
elif [ "${dlext}" = "dll" ]; then
    TDUMP=${target}-objdump
    command -v ${TDUMP} >/dev/null 2>&1 || TDUMP=objdump
    LEAK=$(${TDUMP} -p ${libdir}/libmiradac_c.${dlext} \
           | awk '/Ordinal\/Name Pointer\] Table/{inord=1;next} inord && /^[^\t]/{inord=0} inord && /^\t\[ *[0-9]+\]/{print $NF}' \
           | grep -v -E '^(mdac_|__imp_mdac_)' || true)
else
    LEAK=$(nm -D --defined-only ${libdir}/libmiradac_c.${dlext} | awk '{print $3}' \
           | grep -v -E '^(mdac_|_init$|_fini$|_edata$|_end$|__bss_start$)' || true)
fi
[ -z "${LEAK}" ] || { echo "libmiradac_c exports non-mdac symbols:"; echo "${LEAK}"; exit 1; }
"""

linux_platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc", call_abi="eabihf"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("riscv64", "linux"; libc="glibc"),
]

# BinaryBuilderBase >= 1.x expands the Linux platforms to the cxx11 string ABI only (cxx03 needs
# `old_abis=true`); FreeBSD and macOS use libc++ and the MinGW targets libstdc++ with no
# cxxstring ABI to expand. The darwin legs need capi/CMakeLists.txt from after "capi: choose the
# exported-symbol mechanism per linker", the MinGW legs from after "capi: restrict MinGW DLL
# exports with a generated .def file" and the musl legs from after "Gate AVX2 IFUNC dispatch on
# glibc" — the GitSource commit above (v1.1.3) includes all three.
platforms = vcat(
    expand_cxxstring_abis(linux_platforms),
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
)

products = [
    LibraryProduct("libmiradac_c", :libmiradac_c),
]

# Julia >= 1.10 has GMP_jll 6.2.1 or newer as a stdlib; building against 6.2.1 works with both.
dependencies = [
    Dependency("GMP_jll", v"6.2.1"; compat="6.2.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")
