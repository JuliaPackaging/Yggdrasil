# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_http"
version = v"0.10.9"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-http.git", "acf31399077300c522315612dd2be09cfe48b5b8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-http

# Build 1: Vanilla upstream version
mkdir build-vanilla && cd build-vanilla
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
cd ..

# Save vanilla library artifacts before patching (preserve symlinks/import libs)
vanilla_root=/tmp/aws-c-http-vanilla
mkdir -p ${vanilla_root}/libdir
cp -av ${libdir}/libaws-c-http* ${vanilla_root}/libdir/
if [[ "${libdir}" != "${prefix}/lib" ]]; then
    mkdir -p ${vanilla_root}/lib
    cp -av ${prefix}/lib/libaws-c-http* ${vanilla_root}/lib/
fi

# Apply server-side websocket upgrade patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-Add-support-for-server-side-websocket-upgrade.patch

# Build 2: Patched version with server-side websocket support
mkdir build-patched && cd build-patched
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
cd ..

# Rename patched library and give it a unique SONAME/install_name
if [[ "${target}" == *-mingw* ]]; then
    mv -v ${libdir}/libaws-c-http.${dlext} ${libdir}/libaws-c-http-jq.${dlext}
else
    patched_real=$(realpath ${libdir}/libaws-c-http.${dlext})
    patched_base=$(basename "${patched_real}")
    patched_jq_base=${patched_base/libaws-c-http/libaws-c-http-jq}

    mv -v "${patched_real}" "${libdir}/${patched_jq_base}"
    for l in ${libdir}/libaws-c-http.${dlext}*; do
        if [[ -L "${l}" ]]; then
            rm -f "${l}"
        fi
    done
    if [[ "${patched_jq_base}" != "libaws-c-http-jq.${dlext}" ]]; then
        ln -sf "${patched_jq_base}" "${libdir}/libaws-c-http-jq.${dlext}"
    fi

    PATCHELF_FLAGS=()
    if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
        PATCHELF_FLAGS+=(--page-size 65536)
    fi
    if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
        patchelf ${PATCHELF_FLAGS[@]} --set-soname libaws-c-http-jq.${dlext} ${libdir}/${patched_jq_base}
    elif [[ ${target} == *apple* ]]; then
        install_name_tool -id @rpath/libaws-c-http-jq.${dlext} ${libdir}/${patched_jq_base}
    fi
fi

# Restore vanilla library artifacts
cp -av ${vanilla_root}/libdir/libaws-c-http* ${libdir}/
if [[ -d ${vanilla_root}/lib ]]; then
    cp -av ${vanilla_root}/lib/libaws-c-http* ${prefix}/lib/
fi
"""

platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
# - libaws_c_http: vanilla upstream library
# - libaws_c_http_jq: patched version with server-side websocket upgrade support
products = [
    LibraryProduct("libaws-c-http", :libaws_c_http),
    LibraryProduct("libaws-c-http-jq", :libaws_c_http_jq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("aws_c_compression_jll"; compat="0.3.2"),
    Dependency("aws_c_io_jll"; compat="0.25.0"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
