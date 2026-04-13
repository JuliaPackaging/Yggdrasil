using BinaryBuilder2, YAML

# Given a list of projects (which each have a `build_tarballs.jl` file), use BB2's dry-run capability
# to get a list of `BuildConfig` objects.  We will then emit a structured output back to the calling
# script that allows it to emit buildkite jobs.

# Start by ingesting all build_tarballs into `meta`
const YGGDRASIL_BASE = dirname(dirname(@__DIR__))
meta = BuildMeta(; verbose=false, dry_run=["build"])
for project in ARGS
    run_build_tarballs(meta, joinpath(YGGDRASIL_BASE, project, "build_tarballs.jl"))
end

package_names = [package_config.name for package_config in keys(meta.packagings)]
function get_dep_names(pr::PackageResult)
    dep_names = String[]
    for er in first.(values(pr.config.named_extractions))
        for ts in er.config.build.config.target_specs
            for dep in ts.dependencies
                if !isa(dep, JLLSource)
                    continue
                end

                dep_name = BinaryBuilder2.strip_jll_suffix(dep.package.name)
                if dep_name ∈ package_names
                    push!(dep_names, dep_name)
                end
            end
        end
    end
    return dep_names
end

function project_path(build_result::BuildResult)
    build_script_path = build_result.config.build_script_path
    if isfile(build_script_path)
       build_script_path = dirname(build_script_path) 
    end
    return relpath(build_script_path, YGGDRASIL_BASE)
end


# Next, iterate over `PackageResult` objects; each `PackageResult` will become a registration job,
# and the `BuildConfig`'s from each `PackageResult` will become a build job.  Note that we
# deduplicate `BuildConfig`'s because it's possible for a single build to be packaged into multiple
# separate JLLs.

groups = Dict()
get_group(name) = get!(groups, name, Dict("builds" => [], "packagings" => []))

for (_, package_result) in meta.packagings
    package_deps = get_dep_names(package_result)
    for build_result in collect_builds(package_result)
        group = get_group(project_path(build_result))
        push!(group["builds"], Dict(
            "name" => build_result.config.src_name,
            "script" => build_result.config.build_script_path,
            "build_hash" => spec_hash(build_result.config),
            "platform" => triplet(BinaryBuilder2.get_default_target_spec(build_result.config).platform.target),
            "dependencies" => package_deps,
        ))
    end
    group = get_group(project_path(first(collect_builds(package_result))))
    push!(group["packagings"], Dict(
        "name" => package_result.config.name,
        "dependencies" => package_deps,
    ))
end

# Emit structured output that our caller can interpret.
# We use YAML because it already exists in the `.buildkite` project
YAML.write(stdout, groups)
