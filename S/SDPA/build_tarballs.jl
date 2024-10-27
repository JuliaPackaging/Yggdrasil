# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Together, this allows to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, one can increment the minor or major
# version (depending on whether package using this JLL use `~` or `^` compat entries)
# e.g. go from 200.600.300 to 200.601.300 or 201.600.300
# Similar tricks can also be used to package prerelease versions; e.g. one might
# map a prerelease of 2.7.0 to 200.690.000.

name = "SDPA"
upstream_version = v"7.3.18"
version_offset = v"0.0.0" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build SDPABuilder
sources = [
    ArchiveSource("https://sourceforge.net/projects/sdpa/files/sdpa/sdpa_$(upstream_version).tar.gz",
                  "6fe0cb81ce731345180787c90e3ffdda19184ec67bc7b9d0f80d87c420cb5647")
    DirectorySource("./bundled")
]

MUMPS_seq_version = v"400.1000.0"
MUMPS_seq_packagespec = PackageSpec(; name = "MUMPS_seq_jll",
                                    uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d",
                                    version = MUMPS_seq_version)

METIS_version = v"400.000.300"
METIS_packagespec = PackageSpec(; name = "METIS4_jll",
                                uuid = "40b5814e-7855-5c9f-99f7-a735ce3fdf8b",
                                version = METIS_version)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sdpa-*

if [[ "${target}" == *-mingw* ]]; then
    # This is needed because otherwise we get unusable binaries (error "The specified
    # executable is not a valid application for this OS platform"). These come from
    # CompilerSupportLibraries_jll.
    # xref: https://github.com/JuliaPackaging/Yggdrasil/issues/7904
    #
    # The remove path pattern matches `lib/gcc/<triple>/<major>/`, where `<triple>` is the
    # platform triplet and `<major>` is the GCC major version with which CSL was built
    # xref: https://github.com/JuliaPackaging/Yggdrasil/pull/7535
    #
    # However, before CSL v1.1, these files were located in just `lib/`, thus we clean this
    # directory as well.
    if test -n "$(find $prefix/lib/gcc/*mingw*/*/libgcc*)"; then
        rm $prefix/lib/gcc/*mingw*/*/libgcc* $prefix/lib/gcc/*mingw*/*/libmsvcrt*
    elif test -n "$(find $prefix/lib/libgcc*)"; then
        rm $prefix/lib/libgcc* $prefix/lib/libmsvcrt*
    else
        echo "Could not find any libraries to remove :-/"
        find $prefix/lib
    fi
fi

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# Apply patches
atomic_patch -p1 $WORKSPACE/srcdir/patches/shared.diff
atomic_patch -p1 $WORKSPACE/srcdir/patches/lt_init.diff
autoreconf -vi

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I$prefix/include/coin"
export CXXFLAGS="${CXXFLAGS} -std=c++11"
if [[ ${target} == *mingw* ]]; then
    # Needed for https://github.com/JuliaLang/julia/issues/48081
    export LDFLAGS="-L/opt/$target/$target/sys-root/lib"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

./configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-blas="-lopenblas" --with-lapack="-lopenblas" \
--with-mumps-libs="-L${prefix}/lib -ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis -lopenblas -lgfortran -lpthread" \
--with-mumps-include="-I${prefix}/include/mumps_seq"

make -j${nproc}
make install

## Then build the libcxxwrap-julia wrapper
cd $WORKSPACE/srcdir/sdpawrap

mkdir build
cd build/

if [[ $target == i686-* ]] || [[ $target == arm-* ]]; then
    export processor=pentium4
else
    export processor=x86-64
fi

# Override compiler ID to silence the horrible "No features found" cmake error
if [[ $target == *"apple-darwin"* ]]; then
  macos_extra_flags="-DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
fi

cmake $macos_extra_flags \
      -DCMAKE_FIND_ROOT_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DJulia_PREFIX=${prefix} \
      -DSDPA_DIR=$prefix \
      -DMUMPS_INCLUDE_DIR="../../destdir/include/mumps_seq" \
      -DSDPA_LIBRARY="-lsdpa" \
      -D_GLIBCXX_USE_CXX11_ABI=1 \
      ..
cmake --build . --config Release --target install

if [[ $target == *w64-mingw32* ]] ; then
    cp $WORKSPACE/destdir/lib/libsdpawrap.dll ${libdir}
fi

install_license $WORKSPACE/srcdir/sdpa-*/COPYING
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("sdpa", :sdpa),
    LibraryProduct("libsdpa", :libsdpa),
    LibraryProduct("libsdpawrap", :libsdpawrap)
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = reduce(vcat, libjulia_platforms.(julia_versions))
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) >= v"4", platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="~0.13.2"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("libjulia_jll"),
    BuildDependency(MUMPS_seq_packagespec),
    BuildDependency(METIS_packagespec),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"9",
    clang_use_lld = false,
    julia_compat = "1.6")
