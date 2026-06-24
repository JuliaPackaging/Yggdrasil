include("../common.jl")

name = "Sundials"

sources = get_sources()
products = get_products()
platforms = get_platforms()
dependencies = get_dependencies()

script = install_script * raw"""
    cmake "${CMAKE_FLAGS[@]}" ..
    cmake --build . --parallel ${nproc}
    cmake --install .
"""

for platform in platforms
    should_build_platform(triplet(platform)) || continue
    build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
                   preferred_gcc_version=v"6", julia_compat="1.6")
end
