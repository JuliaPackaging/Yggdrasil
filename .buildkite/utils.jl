import YAML

if !@isdefined(DEBUG)
    const DEBUG = true
end

function upload_pipeline(definition)
    @info "Uploading pipeline..."
    if DEBUG
        YAML.write(stderr, definition)
    else
        open(`buildkite-agent pipeline upload --no-interpolation`, stdout, write=true) do io
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

plugins() = [
    "JuliaCI/julia#v1" => Dict(
        "persist_depot_dirs" => "packages,artifacts,compiled",
        "version" => "1.7"
    )
]

wait_step() = Dict(:wait => "~")
group_step(name, steps) = Dict(:group => name, :steps => steps)

function jll_init_step(NAME, PROJECT, BB_HASH, PROJ_HASH)
    script = raw"""
    # Fail on error
    set -e

    export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

    echo "--- Setup Julia packages"
    julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

    cd ${PROJECT}
    echo "--- Generating meta.json..."
    julia --compile=min ./build_tarballs.jl --meta-json=${NAME}.meta.json
    echo "--- Initializing JLL package..."
    julia ${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci/jll_init.jl ${NAME}.meta.json
    """

    Dict(
        :label => "jll_init -- $NAME",
        :agents => agent(),
        :plugins => plugins(),
        :timeout_in_minutes => 60,
        :concurrency => 1,
        :concurrency_group => "yggdrasil/jll_init",
        :commands => [script],
        :env => Dict(
            "NAME" => NAME,
            "PROJECT" => PROJECT,
            "BB_HASH" => BB_HASH,
            "PROJ_HASH" => PROJ_HASH
        )
    )
end

function build_step(NAME, PLATFORM, PROJECT, BB_HASH, PROJ_HASH)
    script = raw"""
    # Fail on error
    set -e

    export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

    echo "--- Setup Julia packages"
    julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

    # Cleanup temporary things that might have been left-over
    echo "--- Cleanup"
    ./clean_builds.sh
    ./clean_products.sh

    echo "+++ Build"
    cd "${PROJECT}"
    julia ./build_tarballs.jl --verbose "${PLATFORM}"
    """

    Dict(
        :label => "build -- $NAME -- $PLATFORM",
        :agents => agent(),
        :plugins => plugins(),
        :timeout_in_minutes => 60,
        :priority => -1,
        :concurrency => 16,
        :concurrency_group => "yggdrasil/build/$NAME", # Could use ENV["BUILDKITE_JOB_ID"]
        :commands => [script],
        :env => Dict(
            "NAME" => NAME,
            "PLATFORM" => PLATFORM,
            "PROJECT" => PROJECT,
            "BB_HASH" => BB_HASH,
            "PROJ_HASH" => PROJ_HASH
        )
    )
end

function register_step(NAME, PROJECT, BB_HASH, PROJ_HASH)
    script = raw"""
    # Fail on error
    set -e

    export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

    echo "--- Setup Julia packages"
    julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

    cd "${PROJECT}"
    echo "--- Generating meta.json..."
    julia --compile=min ./build_tarballs.jl --meta-json=${NAME}.meta.json
    echo "--- Registering ${NAME}..."
    export BB_HASH PROJ_HASH
    julia ${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci/register_package.jl "${NAME}.meta.json" --verbose
    """

    Dict(
        :label => "register -- $NAME",
        :agents => agent(),
        :plugins => plugins(),
        :timeout_in_minutes => 60,
        :commands => [script],
        :env => Dict(
            "NAME" => NAME,
            "PROJECT" => PROJECT,
            "BB_HASH" => BB_HASH,
            "PROJ_HASH" => PROJ_HASH
        )
    )
end
