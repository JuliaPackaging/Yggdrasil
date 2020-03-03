using BinaryBuilder, Pkg

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
jll_name = string(name, "_jll")
repo_name = string("JuliaBinaryWrappers/", jll_name, ".jl")

@info "Initializing $(repo_name)..."

BinaryBuilder.init_jll_package(name, joinpath(Pkg.devdir(), jll_name), repo_name)
