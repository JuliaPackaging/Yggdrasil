using BinaryBuilder

# Collection of sources required to build OpenBLAS
function openblas_sources(version::VersionNumber; kwargs...)
    openblas_version_sources = Dict(
        v"0.3.9" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/archive/v0.3.9.tar.gz",
                          "17d4677264dfbc4433e97076220adc79b050e4f8a083ea3f853a53af253bc380"),
        ],
        v"0.3.7" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/archive/v0.3.7.tar.gz",
                          "bde136122cef3dd6efe2de1c6f65c10955bbb0cc01a520c2342f5287c28f9379"),
        ],
        v"0.3.5" => [
            ArchiveSource("https://github.com/xianyi/OpenBLAS/archive/v0.3.5.tar.gz",
                          "0950c14bd77c90a6427e26210d6dab422271bc86f9fc69126725833ecdaa0e85"),
        ],
    )
    return [
        openblas_version_sources[version]...,
        DirectorySource("./bundled"),
    ]
end

function openblas_script(;num_64bit_threads::Integer=32, openblas32::Bool=false, kwargs...)
    # Allow some basic configuration
    script = """
    NUM_64BIT_THREADS=$(num_64bit_threads)
    OPENBLAS32=$(openblas32)
    """
    # Bash recipe for building across all platforms
    script *= raw"""
    # We always want threading
    flags=(USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1)

    # We are cross-compiling
    flags+=(CROSS=1 PREFIX=/ "CROSS_SUFFIX=${target}-")

    # We need to use our basic objconv, not a prefixed one:
    flags+=(OBJCONV=objconv)

    # Slim the binaries by not shipping static libs
    flags+=(NO_STATIC=1)

    if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
        if [[ ${OPENBLAS32} == 1 ]]; then
            # We're building an LP64 BLAS with 32-bit BlasInt on a 64-bit platform
            LIBPREFIX=libopenblas
        else
            # We're building an ILP64 BLAS with 64-bit BlasInt
            LIBPREFIX=libopenblas64_
            flags+=(INTERFACE64=1 SYMBOLSUFFIX=64_)
        fi
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

    # On Intel architectures, engage DYNAMIC_ARCH
    if [[ ${proc_family} == intel ]]; then
        flags+=(TARGET= DYNAMIC_ARCH=1)
    # Otherwise, engage a specific target
    elif [[ ${target} == aarch64-* ]]; then
        flags+=(TARGET=ARMV8)
    elif [[ ${target} == arm-* ]]; then
        flags+=(TARGET=ARMV7)
    elif [[ ${target} == powerpc64le-* ]]; then
        flags+=(TARGET=POWER8)
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

    # Next, we set the SONAME of the library to a non-versioned name,
    # so that other projects (such as SuiteSparse) can link against us
    # without needing to be built against a particular version.
    if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
        patchelf --set-soname ${LIBPREFIX}.${dlext} ${prefix}/lib/${LIBPREFIX}.${dlext}
    elif [[ ${target} == *apple* ]]; then
        install_name_tool -id ${LIBPREFIX}.${dlext} ${prefix}/lib/${LIBPREFIX}.${dlext}
    fi
    """

end

# Nothing complicated here; we build for everywhere
openblas_platforms(;kwargs...) = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
function openblas_products(;kwargs...)
    return [
        LibraryProduct(["libopenblas", "libopenblas64_"], :libopenblas)
    ]
end
