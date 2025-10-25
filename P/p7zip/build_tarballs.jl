using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "p7zip"
version_string = "17.06"
version = VersionNumber(version_string)

# Collection of sources required to build p7zip
sources = [
    GitSource("https://github.com/p7zip-project/p7zip",
              "d9c3d157c62e842897d4447db717f813810e1423"),
    FileSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/25.01/7z2501.exe",
               "b96831eec5928384f0543d6b57c1f802952a0f2668e662882c0a785a2b52fb3b"),
    FileSource("https://downloads.sourceforge.net/project/sevenzip/7-Zip/25.01/7z2501-x64.exe",
               "78afa2a1c773caf3cf7edf62f857d2a8a5da55fb0fff5da416074c0d28b2b55f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p7zip*/

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${target} == *mingw* ]]; then
    # It's incredibly frustrating to build p7zip on mingw, so instead we just redistribute 7z
    apk add p7zip

    if [[ ${target} == i686* ]]; then
        7z x -y ${WORKSPACE}/srcdir/7z2501.exe 7z.exe 7z.dll License.txt
    else
        7z x -y ${WORKSPACE}/srcdir/7z2501-x64.exe 7z.exe 7z.dll License.txt
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
            riscv64-linux*)      echo makefile.linux_any_cpu;;
            x86_64-*freebsd*)    echo makefile.freebsd6+;;
            aarch64-*freebsd*)   echo makefile.freebsd6+;;
            x86_64-*darwin*)     echo makefile.macosx_llvm_64bits;;
            aarch64-*darwin*)    echo makefile.macosx_llvm_64bits;;
        esac
    }
    cp -v $(target_makefile) makefile.machine

    # clang doesn't like this c++11 narrowing, so we disable the error
    if [[ "${target}" == *darwin* ]] || [[ "${target}" == *freebsd* ]]; then
        CXXFLAGS="${CXXFLAGS} -Wno-c++11-narrowing"
    fi

    install_license DOC/License.txt

    make -j${nproc} 7za CC="${CC} ${CFLAGS}" CXX="${CXX} ${CXXFLAGS}"
    install -Dvm 755 bin/7za "${bindir}/7z"
fi
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("7z", :p7zip),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=llvm_version)
