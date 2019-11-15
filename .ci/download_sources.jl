using BinaryBuilder

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
BinaryBuilder.download_sources(merged["sources"]; verbose=true)

# Then export platforms to file
open(ARGS[2], "w") do io
    println(io, join(merged["platforms"], " "))
end
