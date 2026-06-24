# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "libspatialite"
version = v"5.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-$(version).tar.gz", "43be2dd349daffe016dd1400c5d11285828c22fea35ca5109f21f3ed50605080"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libspatialite-*

# Since libxml2 no longer supports HTTP, we removed that reference from libspatialite.
atomic_patch -p1 ../patches/libxml2-http-deprecated.patch

# Detection of MinGW and macOS is totally wrong: `target_alias` is empty.  We
# could use `host_alias` (why not `host`?), but we should do regex matching,
# which doesn't work very well with Alpine's (da)sh, easiest thing is to check
# `uname -s`, which is easier to test.
atomic_patch -p1 ../patches/configure-ac-system-detection.patch

update_configure_scripts
autoreconf -vi

if [[ ${target} == *-linux-musl* ]] || [[ ${target} == *-freebsd* ]]; then
    #help find sqlite.h header usually
    export CPPFLAGS="-I${includedir}"
fi

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --includedir=${includedir} \
    --libdir=${libdir} \
    --enable-shared=yes \
    --enable-static=no \
    --enable-geocallbacks=yes \
    --enable-knn=yes \
    --enable-proj=yes \
    --enable-iconv=yes \
    --enable-freexl=no \
    --enable-epsg=yes \
    --enable-geos=yes \
    --enable-geosadvanced=yes \
    --enable-geosreentrant=yes \
    --enable-geos370=yes \
    --enable-gcp=no \
    --enable-rttopo=no \
    --enable-libxml2=yes \
    --enable-minizip=no \
    --enable-geopackage=yes \
    --enable-gcov=no \
    --enable-examples=no \
    --enable-module-only=no

make -j${nproc}
make install

if [[ "${target}" == *-darwin* ]]; then
    # I have no idea how they managed to get the extension wrong only for mod_spatialite,
    # but they did.  Let's rename everything manually, sigh.
    mv "${libdir}/mod_spatialite.8.so" "${libdir}/mod_spatialite.8.${dlext}"
    rm "${libdir}/mod_spatialite.so"
    ln -s "mod_spatialite.8.${dlext}" "${libdir}/mod_spatialite.${dlext}"
    sed -i "s/\.so/.${dlext}/g" ${libdir}/mod_spatialite.la
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("mod_spatialite", :mod_spatialite),
    LibraryProduct("libspatialite", :libspatialite)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SQLite_jll")
    Dependency("GEOS_jll"; compat="~3.13.1")
    Dependency(get_addable_spec("PROJ_jll", v"902.500.100+1"); compat="902.500.100")
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(get_addable_spec("OpenSSL_jll", v"3.0.15+2"); compat="3.0.15", platforms=filter(p -> !(Sys.iswindows(p) || Sys.isapple(p)), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
#GEOS uses preferred of 6, so match that here
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
