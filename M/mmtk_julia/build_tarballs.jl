# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mmtk_julia"
version = v"0.30.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmtk/mmtk-julia.git", "c9e046baf3a0d52fe75d6c8b28f6afd69b045d95")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mmtk-julia/
MMTK_PLANS=("Immix" "StickyImmix")
MMTK_MOVING=(0 1)
MMTK_BUILD=("debug" "release")

# Build MMTK (all configurations)
for build in "${MMTK_BUILD[@]}"; do
    for plan in "${MMTK_PLANS[@]}"; do
        for moving in "${MMTK_MOVING[@]}"; do
            # Build MMTK
            MMTK_PLAN=$plan MMTK_MOVING=$moving make $build

            if [ "$moving" == 1 ]; then
                moving_name="moving"
            else
                moving_name="non_moving"
            fi

            if [ "$plan" == "Immix" ]; then
                plan_name="immix"
            else [ "$plan" == "StickyImmix" ]
                plan_name="sticky"
            fi

            # Install files
            install -Dvm 755 "mmtk/target/${rust_target}/${build}/libmmtk_julia.${dlext}" -t "${libdir}/${plan_name}/${moving_name}/${build}/"
        done
    done
done

# Install header files
install -Dvm 644 "mmtk/api/mmtk.h" "${includedir}/mmtk.h"
install -Dvm 644 "mmtk/api/mmtkMutator.h" "${includedir}/mmtkMutator.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
# We will build the cartesian product of all plans, moving and build types for MMTk
products = [
    LibraryProduct("immix/non_moving/debug/libmmtk_julia", :libmmtk_julia_immix_non_moving_debug; dont_dlopen=true)
    LibraryProduct("immix/moving/debug/libmmtk_julia", :libmmtk_julia_immix_moving_debug; dont_dlopen=true)
    LibraryProduct("immix/non_moving/release/libmmtk_julia", :libmmtk_julia_immix_non_moving_release; dont_dlopen=true)
    LibraryProduct("immix/moving/release/libmmtk_julia", :libmmtk_julia_immix_moving_release; dont_dlopen=true)
    LibraryProduct("sticky/non_moving/debug/libmmtk_julia", :libmmtk_julia_sticky_non_moving_debug; dont_dlopen=true)
    LibraryProduct("sticky/moving/debug/libmmtk_julia", :libmmtk_julia_sticky_moving_debug; dont_dlopen=true)
    LibraryProduct("sticky/non_moving/release/libmmtk_julia", :libmmtk_julia_sticky_non_moving_release; dont_dlopen=true)
    LibraryProduct("sticy/moving/release/libmmtk_julia", :libmmtk_julia_sticky_moving_release; dont_dlopen=true)
    FileProduct("include/mmtk.h", :mmtk_h)
    FileProduct("include/mmtkMutator.h", :mmtkMutator_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"10", dont_dlopen=true)
