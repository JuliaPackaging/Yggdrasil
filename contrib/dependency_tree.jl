using BinaryBuilder

const PATH = dirname(@__DIR__)
build_recipes = readlines(`find $(PATH) -name build_tarballs.jl`)

function process_meta(file)
    # Read in input `.json` file
    json = String(read(file))
    buff = IOBuffer(strip(json))
    objs = []
    while !eof(buff)
        push!(objs, BinaryBuilder.JSON.parse(buff))
    end

    # Merge the multiple outputs into one
    merged = BinaryBuilder.merge_json_objects(objs)
    BinaryBuilder.cleanup_merged_object!(merged)
    merged
end

metadata = Any[]
failed = String[]

for recipe in build_recipes
    @info "Processing recipe..." recipe
    try 
        run(`$(Base.julia_cmd()) $recipe --meta-json=tmp.json`)
        meta = process_meta("tmp.json")
        rm("tmp.json")
        push!(metadata, meta)
    catch err
        bt = catch_backtrace()
        push!(failed, recipe)
        @error "Processing failed..." recipe _ex=(err, bt)
    end
end

Base.nameof(d::BinaryBuilder.AbstractDependency) = d.pkg.name
function stages(metadata)

    seen = Set{String}()
    stages = Any[]
    current = Any[]
    next = Any[]
    worklist = metadata

    while true
        changed = false
        for pkg in worklist
            dependencies = pkg["dependencies"]
            name = "$(pkg["name"])_jll"
        
            if all(d->in(nameof(d), seen), dependencies)
                changed = true
                push!(seen, name)
                push!(current, pkg)
            else
                push!(next, pkg)
            end
        end
        if !changed
            if !isempty(next)
                @error "Unsatisfiable dependencies or loop"
            end
            break
        end
        push!(stages, current)
        worklist = next
        current = Any[]
        next = Any[]
    end
    return stages, next
end

function report(stages)
    open("report.md", "w") do io
        for (i, stage) in enumerate(stages)
            println(io, "- Stage ", i, ":")
            for pkg in stage
                println(io, "  - `", pkg["name"], "`")
            end
        end
    end
end










