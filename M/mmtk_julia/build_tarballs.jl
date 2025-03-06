# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mmtk_julia"
version = v"0.30.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmtk/mmtk-julia.git", "4933fb41ba5d1d21f720e2ca1bfa5bc938b73b12")
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
    LibraryProduct("libmmtk_julia", :libmmtk_julia_immix_moving_debug, "lib/immix/moving/debug"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_immix_non_moving_debug, "lib/immix/non_moving/debug"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_immix_moving_release, "lib/immix/moving/release"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_immix_non_moving_release, "lib/immix/non_moving/release"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_sticky_moving_debug, "lib/sticky/moving/debug"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_sticky_non_moving_debug, "lib/sticky/non_moving/debug"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_sticky_moving_release, "lib/sticky/moving/release"; dont_dlopen=true)
    LibraryProduct("libmmtk_julia", :libmmtk_julia_sticky_non_moving_release, "lib/sticky/non_moving/release"; dont_dlopen=true)
    FileProduct("include/mmtk.h", :mmtk_h)
    FileProduct("include/mmtkMutator.h", :mmtkMutator_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"10", dont_dlopen=true)
