import YAML

if !@isdefined(DEBUG)
    const DEBUG = true
end

function upload_pipeline(definition)
    @info "Uploading pipeline..."
    if DEBUG
        YAML.write(stderr, definition)
    else
        open(`buildkite-agent pipeline upload`, stdout, write=true) do io
            YAML.write(io, definition)
        end
    end
end

function annotate(annotation; context="default", style="info", append=true)
    @assert style in ("success", "info", "warning", "error")
    @info "Uploading annotation..."
    if DEBUG
        write(stderr, annotation, '\n')
    else
        append = append ? `--append` : ``
        cmd = `buildkite-agent annotate --style $(style) --context $(context) $(append)`
        open(cmd, stdout, write=true) do io
            write(io, annotation)
        end
    end
end

agent() = Dict(
                :queue => "juliaecosystem",
                :arch => "x86_64",
                :os => "linux",
                :sandbox_capable => "true"
            )
wait_step() = Dict(:wait => "~")
group_step(name, steps) = Dict(:group => name, :steps => steps)

function jll_init_step(NAME, PROJECT, BB_HASH, PROJ_HASH)
    Dict(
        :label => "jll_init -- $NAME",
        :agents => agent(),
        :timeout_in_minutes => 60,
        :concurrency => 1,
        :concurrency_group => "yggdrasil/jll_init",
        :commands => [
            "true"
        ]
    )
end

function build_step(NAME, PLATFORM, PROJECT, BB_HASH, PROJ_HASH)
    Dict(
        :label => "build -- $NAME -- $PLATFORM",
        :agents => agent(),
        :timeout_in_minutes => 60,
        :priority => -1,
        :concurrency => 16,
        :concurrency_group => "yggdrasil/build/$NAME", # Could use ENV["BUILDKITE_JOB_ID"]
        :commands => [
            "true"
        ]
    )
end

function register_step(NAME, PROJECT, BB_HASH, PROJ_HASH)
    Dict(
        :label => "register -- $NAME",
        :agents => agent(),
        :timeout_in_minutes => 60,
        :commands => [
            "true"
        ]
    )
end
