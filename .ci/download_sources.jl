using BinaryBuilder, Pkg
using BinaryBuilder: download_source

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

# Download all sources, unless we're in a skip build situation
if get(ENV, "SKIP_BUILD", "false") != "true"
    download_source.(merged["sources"]; verbose=true)
end

# Also initialize JLL package directories
src_name = merged["name"]
code_dir = joinpath(Pkg.devdir(), "$(src_name)_jll")
# Always start from a clean slate
rm(code_dir; recursive=true, force=true)

# Then export platforms to file
open(ARGS[2], "w") do io
    println(io, join(triplet.(merged["platforms"]), " "))
end
