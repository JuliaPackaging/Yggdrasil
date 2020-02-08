using BinaryBuilder, Pkg

verbose = "--verbose" in ARGS

# Read in input `.json` file
json = String(read(ARGS[1]))
buff = IOBuffer(strip(json))
objs = []
while !eof(buff)
    push!(objs, BinaryBuilder.JSON.parse(buff))
end

# Merge the multiple outputs into one
merged = BinaryBuilder.merge_json_objects(objs)
BinaryBuilder.cleanup_merged_object!(merged)

# Determine build version
name = merged["name"]
version = merged["version"]
dependencies = [dep for dep in merged["dependencies"] if !isa(dep, BuildDependency)]
lazy_artifacts = merged["lazy_artifacts"]
build_version = BinaryBuilder.get_next_wrapper_version(name, version)

# Register JLL package using given metadata
BinaryBuilder.init_jll_package(
    name,
    joinpath(Pkg.devdir(), "$(name)_jll"),
    "JuliaBinaryWrappers/$(name)_jll.jl",
)

for obj in objs
    BinaryBuilder.cleanup_merged_object!(obj)
    BinaryBuilder.rebuild_jll_packages(obj; verbose=verbose, lazy_artifacts=lazy_artifacts)
end
BinaryBuilder.push_jll_package(name, build_version)
BinaryBuilder.register_jll(name, build_version, dependencies)
