include("../common.jl")
name = "Sundials_GPU"

include(normpath(joinpath(YGGDRASIL_DIR, "..", "platforms", "cuda.jl")))

sources = get_sources()

# Add the GPU products
products = get_products()
push!(products, LibraryProduct("libsundials_nveccuda", :libsundials_nveccuda))

# Pick all the standard depedencies  
dependencies = get_dependencies()

# Override the default platforms
platforms = CUDA.supported_platforms(; max_version = v"12.9.1")   # Doesn't build with CUDA 13 right now
filter!(p -> (os(p) == "linux") && arch(p) == "x86_64", platforms)
platforms = expand_gfortran_versions(platforms)

script = install_script * raw"""
    # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
    # make it use the workspace instead
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir ${TMPDIR}

    export CUDA_HOME=${WORKSPACE}/destdir/cuda
    export PATH=$PATH:$CUDA_HOME/bin

    cmake "${CMAKE_FLAGS[@]}" -DENABLE_CUDA=ON ..
    cmake --build . --parallel ${nproc}
    cmake --install .
"""

# Build for all supported CUDA toolkits 
for platform in platforms

    should_build_platform(triplet(platform)) || continue

    # Need the static SDK to let CMake detect the compiler properly
    cuda_deps = CUDA.required_dependencies(platform)
    push!(cuda_deps,
          BuildDependency(PackageSpec(name="CUDA_full_jll",
                                      version=CUDA.full_version(VersionNumber(platform.tags["cuda"]))))
          )

    build_tarballs(ARGS, name, ygg_version, sources, script, [platform], products,
                   [dependencies; cuda_deps];
                   preferred_gcc_version=v"9", julia_compat="1.6",
                   augment_platform_block=CUDA.augment)

end
