using BinaryBuilder, Pkg
using BinaryBuilder: download_source

# Read in input `.json` file, which has one JSON object per line
objs = [BinaryBuilder.JSON.parse(line; dicttype=Dict) for line in eachline(ARGS[1]) if !isempty(strip(line))]

# Merge the multiple outputs into one
merged = BinaryBuilder.merge_json_objects(objs)
BinaryBuilder.cleanup_merged_object!(merged)

# Then export platforms to file
open(ARGS[2], "w") do io
    println(io, join(triplet.(merged["platforms"]), " "))
end
