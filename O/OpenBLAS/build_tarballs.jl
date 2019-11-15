using BinaryBuilder

# Collection of sources required to build OpenBLAS
name = "OpenBLAS"
version = v"0.3.7"
sources = [
    "https://github.com/xianyi/OpenBLAS/archive/v$(version).tar.gz" =>
    "bde136122cef3dd6efe2de1c6f65c10955bbb0cc01a520c2342f5287c28f9379",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
# We always want threading
flags=(USE_THREAD=1 GEMM_MULTITHREADING_THRESHOLD=50 NO_AFFINITY=1)

# We are cross-compiling
flags+=(CROSS=1 PREFIX=/ "CROSS_SUFFIX=${target}-")

# We need to use our basic objconv, not a prefixed one:
flags+=(OBJCONV=objconv)

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    # If we're building for a 64-bit platform (that is not aarch64), engage ILP64
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
    flags+=(NUM_THREADS=32)
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
    LDFLAGS="${LDFLAGS} '-Wl,-rpath,\$\$ORIGIN' -Wl,-z,origin"
elif [[ ${target} == *apple* ]]; then
    LDFLAGS="${LDFLAGS} -Wl,-rpath,@loader_path/"
fi


# Enter the fun zone
cd ${WORKSPACE}/srcdir/OpenBLAS-*/

# Build the actual library
make "${flags[@]}"

# Install the library
make "${flags[@]}" "PREFIX=$prefix" install

# Force the library to be named the same as in Julia-land.
# Move things around, fix symlinks, and update install names/SONAMEs.
ls -la ${prefix}/lib
for f in ${prefix}/lib/libopenblas*p-r0*; do
    name=${LIBPREFIX}.0.${f#*.}

    # Move this file to a julia-compatible name
    mv -v ${f} ${prefix}/lib/${name}

    # If there were links that are now broken, fix 'em up
    for l in $(find ${prefix}/lib -xtype l); do
        if [[ $(basename $(readlink ${l})) == $(basename ${f}) ]]; then
            ln -vsf ${name} ${l}
        fi
    done

    # If this file was a .so or .dylib, set its SONAME/install name
    if [[ ${f} == *.so.* ]] || [[ ${f} == *.dylib ]]; then 
        if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
            patchelf --set-soname ${name} ${prefix}/lib/${name}
        elif [[ ${target} == *apple* ]]; then
            install_name_tool -id ${name} ${prefix}/lib/${name}
        fi
    fi
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libopenblas", "libopenblas64_"], :libopenblas)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
