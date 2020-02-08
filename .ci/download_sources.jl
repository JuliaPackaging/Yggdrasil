using BinaryBuilder, Pkg
using BinaryBuilder: download_source, sourcify, init_jll_package

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

# Download all sources
download_source.(merged["sources"]; verbose=true)

# Also initialize JLL package directories
src_name = merged["name"]
code_dir = joinpath(Pkg.devdir(), "$(src_name)_jll")
deploy_repo = "JuliaBinaryWrappers/$(src_name)_jll.jl"
# Always start from a clean slate
rm(code_dir; recursive=true, force=true)
init_jll_package(src_name, code_dir, deploy_repo)

# Then export platforms to file
open(ARGS[2], "w") do io
    println(io, join(triplet.(merged["platforms"]), " "))
end
