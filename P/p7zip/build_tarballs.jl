using BinaryBuilder

name = "p7zip"
version = v"16.02"

# Collection of sources required to build p7zip
sources = [
    "https://downloads.sourceforge.net/project/p7zip/p7zip/16.02/p7zip_16.02_src_all.tar.bz2" =>
    "5eb20ac0e2944f6cb9c2d51dd6c4518941c185347d4089ea89087ffdd6e2341f",
    "https://downloads.sourceforge.net/project/sevenzip/7-Zip/19.00/7z1900.exe" =>
    "759aa04d5b03ebeee13ba01df554e8c962ca339c74f56627c8bed6984bb7ef80",
    "https://downloads.sourceforge.net/project/sevenzip/7-Zip/19.00/7z1900-x64.exe" =>
    "0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p7zip_*/

if [[ ${target} == *mingw* ]]; then
    # It's incredibly frustrating to build p7zip on mingw, so instead we just redistribute 7z
    apk add p7zip

    mkdir ${prefix}/bin
    cd ${prefix}/bin
    if [[ ${target} == i686* ]]; then
        7z x -y ${WORKSPACE}/srcdir/*-7z1900.exe 7z.exe 7z.dll
    else
        7z x -y ${WORKSPACE}/srcdir/*-7z1900-x64.exe 7z.exe 7z.dll
    fi
    chmod +x 7z.exe 7z.dll
else
    # Build requirements
    apk add nasm yasm

    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/12-CVE-2016-9296.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/13-CVE-2017-17969.patch
    atomic_patch -p4 ${WORKSPACE}/srcdir/patches/15-Enhanced-encryption-strength.patch

    # Convert from target to makefile:
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
        esac
    }
    cp $(target_makefile) makefile.machine

    # clang doesn't like this c++11 narrowing, so we disable the error
    if [[ "${target}" == *darwin* ]] || [[ "${target}" == *freebsd* ]]; then
        CXXFLAGS="${CXXFLAGS} -Wno-c++11-narrowing"
    fi

    make -j${nproc} 7za CC="${CC} ${CFLAGS}" CXX="${CXX} ${CXXFLAGS}"
    mkdir -p ${prefix}/bin
    cp -a bin/7za ${prefix}/bin/7z
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("7z", :p7zip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

