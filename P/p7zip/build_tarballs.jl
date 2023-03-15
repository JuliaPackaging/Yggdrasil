using BinaryBuilder

name = "p7zip"
version_string = "17.04"
version = VersionNumber(version_string)

# Collection of sources required to build p7zip
sources = [
    ArchiveSource("https://github.com/p7zip-project/p7zip/archive/refs/tags/v$(version_string).tar.gz",
                  "ea029a2e21d2d6ad0a156f6679bd66836204aa78148a4c5e498fe682e77127ef"),
    FileSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/21.07/7z2107.exe",
               "71e94e6038f4d42ed8f0f38c0e6c3846f21d13527139efa9ef8b8f6312ab6c90"),
    FileSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/21.07/7z2107-x64.exe",
               "0b461f0a0eccfc4f39733a80d70fd1210fdd69f600fb6b657e03940a734e5fc1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p7zip-*/

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${target} == *mingw* ]]; then
    # It's incredibly frustrating to build p7zip on mingw, so instead we just redistribute 7z
    apk add p7zip

    if [[ ${target} == i686* ]]; then
        7z x -y ${WORKSPACE}/srcdir/7z2107.exe 7z.exe 7z.dll License.txt
    else
        7z x -y ${WORKSPACE}/srcdir/7z2107-x64.exe 7z.exe 7z.dll License.txt
    fi

    install_license License.txt

    chmod +x 7z.exe 7z.dll
    mkdir ${prefix}/bin
    cp -a 7z.exe 7z.dll ${prefix}/bin
else
    # Build requirements
    apk add nasm yasm

    # Convert from target to makefile
    target_makefile()
    {
        case "${target}" in
            x86_64-linux*)       echo makefile.linux_amd64_asm;;
            i686-linux*)         echo makefile.linux_x86_asm_gcc_4.X;;
            powerpc64le*linux*)  echo makefile.linux_cross_ppc64le;;
            aarch64*linux*)      echo makefile.linux_cross_aarch64;;
            arm-*linux*)         echo makefile.linux_cross_arm;;
            x86_64-*freebsd*)    echo makefile.freebsd6+;;
            x86_64-*darwin*)     echo makefile.macosx_llvm_64bits;;
            aarch64-*darwin*)    echo makefile.macosx_llvm_64bits;;
        esac
    }
    cp $(target_makefile) makefile.machine

    # clang doesn't like this c++11 narrowing, so we disable the error
    if [[ "${target}" == *darwin* ]] || [[ "${target}" == *freebsd* ]]; then
        CXXFLAGS="${CXXFLAGS} -Wno-c++11-narrowing"
    fi

    install_license DOC/License.txt

    make -j${nproc} 7za CC="${CC} ${CFLAGS}" CXX="${CXX} ${CXXFLAGS}"
    mkdir -p ${prefix}/bin
    cp -a bin/7za ${prefix}/bin/7z
fi
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("7z", :p7zip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
