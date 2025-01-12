using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

# Collection of sources required to build OpenBLAS
function openblas_sources(version::VersionNumber; kwargs...)
    openblas_version_sources = Dict(
        v"0.3.29" => [
            ArchiveSource("https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.29/OpenBLAS-0.3.29.tar.gz",
                          "38240eee1b29e2bde47ebb5d61160207dc68668a54cac62c076bb5032013b1eb")
        ],
        v"0.3.28" => [
            ArchiveSource("https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.28/OpenBLAS-0.3.28.tar.gz",
                          "f1003466ad074e9b0c8d421a204121100b0751c96fc6fcf3d1456bd12f8a00a1")
        ],
        v"0.3.27" => [
            ArchiveSource("https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.27/OpenBLAS-0.3.27.tar.gz",
                          "aa2d68b1564fe2b13bc292672608e9cdeeeb6dc34995512e65c3b10f4599e897")
        ],
        v"0.3.26" => [
            ArchiveSource("https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.26/OpenBLAS-0.3.26.tar.gz",
                          "4e6e4f5cb14c209262e33e6816d70221a2fe49eb69eaf0a06f065598ac602c68")
        ],
        v"0.3.25" => [
            ArchiveSource("https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.25/OpenBLAS-0.3.25.tar.gz",
                          "4c25cb30c4bb23eddca05d7d0a85997b8db6144f5464ba7f8c09ce91e2f35543")
        ],
        v"0.3.24" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.24/OpenBLAS-0.3.24.tar.gz",
                          "ceadc5065da97bd92404cac7254da66cc6eb192679cf1002098688978d4d5132")
        ],
        v"0.3.23" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.23/OpenBLAS-0.3.23.tar.gz",
                          "5d9491d07168a5d00116cdc068a40022c3455bf9293c7cb86a65b1054d7e5114")
        ],
        v"0.3.22" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.22/OpenBLAS-0.3.22.tar.gz",
                          "7fa9685926ba4f27cfe513adbf9af64d6b6b63f9dcabb37baefad6a65ff347a7")
        ],
        v"0.3.21" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.21/OpenBLAS-0.3.21.tar.gz",
                          "f36ba3d7a60e7c8bcc54cd9aaa9b1223dd42eaf02c811791c37e8ca707c241ca")
        ],
        v"0.3.20" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.20/OpenBLAS-0.3.20.tar.gz",
                          "8495c9affc536253648e942908e88e097f2ec7753ede55aca52e5dead3029e3c")
        ],
        v"0.3.19" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.19/OpenBLAS-0.3.19.tar.gz",
                          "947f51bfe50c2a0749304fbe373e00e7637600b0a47b78a51382aeb30ca08562")
        ],
        v"0.3.17" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.17/OpenBLAS-0.3.17.tar.gz",
                          "df2934fa33d04fd84d839ca698280df55c690c86a5a1133b3f7266fce1de279f")
        ],
        v"0.3.13" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.13/OpenBLAS-0.3.13.tar.gz",
                          "79197543b17cc314b7e43f7a33148c308b0807cd6381ee77f77e15acf3e6459e")
        ],
        v"0.3.12" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.12/OpenBLAS-0.3.12.tar.gz",
                          "65a7d3a4010a4e3bd5c0baa41a234797cd3a1735449a4a5902129152601dc57b")
        ],
        v"0.3.10" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.10/OpenBLAS-0.3.10.tar.gz",
                          "0484d275f87e9b8641ff2eecaa9df2830cbe276ac79ad80494822721de6e1693"),
        ],
        v"0.3.9" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.9/OpenBLAS-0.3.9.tar.gz",
                          "17d4677264dfbc4433e97076220adc79b050e4f8a083ea3f853a53af253bc380"),
        ],
        v"0.3.7" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.7/OpenBLAS-0.3.7.tar.gz",
                          "bde136122cef3dd6efe2de1c6f65c10955bbb0cc01a520c2342f5287c28f9379"),
        ],
        v"0.3.5" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/releases/download/v0.3.5/OpenBLAS-0.3.5.tar.gz",
                          "0950c14bd77c90a6427e26210d6dab422271bc86f9fc69126725833ecdaa0e85"),
        ],
    )
    return [
        openblas_version_sources[version]...,
        DirectorySource("./bundled"),
    ]
end

# Do not override the default `num_64bit_threads` here, instead pass a custom from specific OpenBLAS versions
# that should opt into a higher thread count.
function openblas_script(;num_64bit_threads::Integer=32, openblas32::Bool=false, aarch64_ilp64::Bool=false, consistent_fpcsr::Bool=false, bfloat16::Bool=false, kwargs...)
    # Allow some basic configuration
    script = """
    NUM_64BIT_THREADS=$(num_64bit_threads)
    OPENBLAS32=$(openblas32)
    AARCH64_ILP64=$(aarch64_ilp64)
    CONSISTENT_FPCSR=$(consistent_fpcsr)
    BFLOAT16=$(bfloat16)
    version_patch=$(version.patch)
    """
    # Bash recipe for building across all platforms
    script *= raw"""
    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # For msan, we need to use flang to compile.
        ## Create flang compiler wrapper
        cat /opt/bin/${bb_full_target}/${target}-clang | sed 's/clang/flang/g' > /opt/bin/${bb_full_target}/${target}-flang
        chmod +x /opt/bin/${bb_full_target}/${target}-flang
        ln -s ${WORKSPACE}/x86_64-linux-musl-cxx11/destdir/bin/flang /opt/x86_64-linux-musl/bin/flang
        cp ${WORKSPACE}/x86_64-linux-musl-cxx11/destdir/include/*.mod /opt/x86_64-linux-musl/include
        export FC=${target}-flang

        # Install flang rt libraries to sysroot
        cp ${prefix}/lib/lib{flang*,ompstub*,pgmath*,omp*} /opt/${target}/${target}/sys-root/usr/lib/

        # Install msan runtime (for clang)
        cp -rL ${prefix}/lib/linux/* /opt/x86_64-linux-musl/lib/clang/13.0.1/lib/linux/

        # Install msan runtime (for flang)
        mkdir -p $(dirname $(readlink -f $(which flang)))/../lib/clang/13.0.1/lib/linux
        cp -rL ${prefix}/lib/linux/* $(dirname $(readlink -f $(which flang)))/../lib/clang/13.0.1/lib/linux/
    fi

    # We always want threading
    flags=(USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=400 NO_AFFINITY=1)
    if [[ "${CONSISTENT_FPCSR}" == "true" ]]; then
        flags+=(CONSISTENT_FPCSR=1)
    fi

    # Build BFLOAT16 kernels
    if [[ "${BFLOAT16}" == "true" ]]; then
        flags+=(BUILD_BFLOAT16=1)
    fi

    # We are cross-compiling
    flags+=(CROSS=1 PREFIX=/ "CROSS_SUFFIX=${target}-")

    # We need to use our basic objconv, not a prefixed one:
    flags+=(OBJCONV=objconv)

    # Slim the binaries by not shipping static libs
    flags+=(NO_STATIC=1)

    if [[ ${nbits} == 64 ]] && [[ "${OPENBLAS32}" != "true" ]] && [[ "${AARCH64_ILP64}${target}" != "falseaarch64-"* ]]; then
        # We're building an ILP64 BLAS with 64-bit BlasInt
        LIBPREFIX=libopenblas64_
        flags+=(INTERFACE64=1 SYMBOLSUFFIX=64_)
    else
        LIBPREFIX=libopenblas
    fi
    flags+=("LIBPREFIX=${LIBPREFIX}")

    # Set BINARY=32 on 32-bit platforms, use fewer threads on 32-bit arch
    if [[ ${nbits} == 32 ]]; then
        flags+=(BINARY=32)
        flags+=(NUM_THREADS=8)
    else
        # We parameterize this for the OpenBLASHighThreadCount package
        flags+=(NUM_THREADS=${NUM_64BIT_THREADS})
    fi

    # Set BINARY=64 on x86_64 platforms (but not AArch64 or powerpc64le)
    if [[ ${target} == x86_64-* ]]; then
        flags+=(BINARY=64)
    fi

    # On Intel and most aarch64 architectures, engage DYNAMIC_ARCH.
    # When using DYNAMIC_ARCH the TARGET specifies the minimum architecture requirement.
    if [[ ${bb_full_target} == *-sanitize* ]]; then
        # Currently, OpenBLAS has no sanitizer annotations around its assembly kernels, so build the
        # C versions. Once we have those annotations, we can remove this branch.
        flags+=(TARGET=GENERIC)
    elif [[ ${proc_family} == intel ]]; then
        flags+=(DYNAMIC_ARCH=1)
        # Before OpenBLAS 0.3.13, there appears to be a miscompilation bug with `clang` on setting `TARGET=GENERIC`
        # As that is the case, we're just going to be safe and only use `TARGET=GENERIC` on 0.3.13+
        if [ ${version_patch} -gt 12 ]; then
            flags+=(TARGET=GENERIC)
        else
            flags+=(TARGET=)
        fi
    elif [[ ${target} == aarch64-* ]] && [[ ${bb_full_target} != *-libgfortran3* ]]; then
        flags+=(TARGET=ARMV8 DYNAMIC_ARCH=1)
    # Otherwise, engage a specific target
    elif [[ ${bb_full_target} == aarch64*-libgfortran3* ]]; then
        # Old GCC versions, with libgfortran3, can't build for newer
        # microarchitectures, let's just use the generic one
        flags+=(TARGET=ARMV8)
    elif [[ ${target} == arm-* ]]; then
        flags+=(TARGET=ARMV7)
    elif [[ ${target} == powerpc64le-* ]]; then
        flags+=(TARGET=POWER8 DYNAMIC_ARCH=1)
    elif [[ ${target} == riscv64-* ]]; then
        flags+=(TARGET=RISCV64_GENERIC DYNAMIC_ARCH=1)
    fi

    # If we're building for x86_64 Windows gcc7+, we need to disable usage of
    # certain AVX-512 registers (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65782)
    if [[ ${target} == x86_64-w64-mingw32 ]] && [[ $(gcc --version | head -1 | awk '{ print $3 }') =~ (7|8).* ]]; then
        CFLAGS="${CFLAGS} -fno-asynchronous-unwind-tables"
    fi

    # Because we use this OpenBLAS within Julia, and often want to bundle our
    # libgfortran and other friends alongside, we need an RPATH of '$ORIGIN',
    # so set it here.
    if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
        export LDFLAGS="${LDFLAGS} '-Wl,-rpath,\$\$ORIGIN' -Wl,-z,origin"
    elif [[ ${target} == *apple* ]]; then
        export LDFLAGS="${LDFLAGS} -Wl,-rpath,@loader_path/"
    fi


    # Enter the fun zone
    cd ${WORKSPACE}/srcdir/OpenBLAS*/

    # Apply any patches this version of OpenBLAS requires
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        atomic_patch -p1 ${f}
    done

    # Build the actual library
    make "${flags[@]}"

    # Install the library
    make "${flags[@]}" "PREFIX=$prefix" install

    # Force the library to be named the same as in Julia-land.
    # Move things around, fix symlinks, and update install names/SONAMEs.
    ls -la ${prefix}/lib

    # Ensure empty loop when no files match
    shopt -s nullglob

    for f in ${prefix}/lib/libopenblas*p-r0*; do
        name=${LIBPREFIX}.0.${f#*.}

        # Move this file to a julia-compatible name, that is to say,
        # from `libopenblas64_p-r0.3.7.a` to `libopenblas64_.0.3.7.a`
        mv -v ${f} ${prefix}/lib/${name}

        # If there were links that are now broken, fix 'em up
        for l in $(find ${prefix}/lib -xtype l); do
            if [[ $(basename $(readlink ${l})) == $(basename ${f}) ]]; then
                ln -vsf ${name} ${l}
            fi
        done
    done

    PATCHELF_FLAGS=()

    # ppc64le and aarch64 have 64KB page sizes, don't muck up the ELF section load alignment
    if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
        PATCHELF_FLAGS+=(--page-size 65536)
    fi

    # Next, we set the SONAME of the library to a non-versioned name,
    # so that other projects (such as SuiteSparse) can link against us
    # without needing to be built against a particular version.
    if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
        patchelf ${PATCHELF_FLAGS[@]} --set-soname ${LIBPREFIX}.${dlext} ${prefix}/lib/${LIBPREFIX}.${dlext}
    elif [[ ${target} == *apple* ]]; then
        install_name_tool -id ${LIBPREFIX}.${dlext} ${prefix}/lib/${LIBPREFIX}.${dlext}
    fi
    """

end

# Nothing complicated here; we build for everywhere
openblas_platforms(;experimental::Bool=true, kwargs...) = expand_gfortran_versions(supported_platforms(;experimental))

# The products that we will ensure are always built
function openblas_products(;kwargs...)
    return [
        LibraryProduct(["libopenblas", "libopenblas64_"], :libopenblas)
    ]
end

function openblas_dependencies(platforms; llvm_compilerrt_version=v"13.0.1", kwargs...)
    return [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        HostBuildDependency(PackageSpec(name="FlangClassic_jll", uuid="b3f849d4-7198-5f76-a9c5-8e4f35f75d39")),
        BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_compilerrt_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
        BuildDependency(PackageSpec(name="FlangClassic_RTLib_jll", uuid="48abaad9-6585-5455-9ce3-84cd0709264b"); platforms=filter(p -> sanitize(p)=="memory", platforms))
    ]
end
