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

# Human-readable platform of a build, used in CI step labels.  This is the platform of the
# default target spec; builds that also target other platforms (e.g. cross-compilers, whose
# default spec is the host the compiler runs on) append those targets, e.g.
# `x86_64-linux-gnu => aarch64-linux-musl`.
function platform_label(config::BuildConfig)
    default_spec = BinaryBuilder2.get_default_target_spec(config)
    extra_specs = filter(ts -> isdisjoint(ts.flags, (:default, :native)), config.target_specs)
    return join([triplet(ts.platform.target) for ts in [default_spec; extra_specs]], " => ")
end

# The platform of the agents that load-check the JLLs (see `agent()` in `.buildkite/utils.jl`)
const LOAD_CHECK_PLATFORM = Platform("x86_64", "linux"; libc="glibc")

# Whether the JLL's wrapper can select an artifact of `platform` on the load-check agents.
# JLLs encode a `CrossPlatform` with the host as the base platform and the target in
# `target_*` tags, or, for a host of `any`, with the target as the base platform; only the
# base platform's architecture, OS and libc matter here, as the agent's other tags depend
# on the Julia version that runs the check.
loadable_on_load_check_agent(::AnyPlatform) = true
loadable_on_load_check_agent(cp::CrossPlatform) = loadable_on_load_check_agent(cp.encoded)
function loadable_on_load_check_agent(p::Platform)
    return arch(p) == arch(LOAD_CHECK_PLATFORM) && os(p) == os(LOAD_CHECK_PLATFORM) &&
           libc(p) == libc(LOAD_CHECK_PLATFORM)
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
        build_hash = spec_hash(build_result.config)
        idx = findfirst(b -> b["build_hash"] == build_hash, group["builds"])
        if idx !== nothing
            # This build was already scheduled by another of its JLLs
            union!(group["builds"][idx]["dependencies"], package_deps)
            continue
        end
        push!(group["builds"], Dict(
            "name" => build_result.config.src_name,
            "script" => build_result.config.build_script_path,
            "build_hash" => build_hash,
            "platform" => platform_label(build_result.config),
            "dependencies" => copy(package_deps),
        ))
    end
    group = get_group(project_path(first(collect_builds(package_result))))
    push!(group["packagings"], Dict(
        "name" => package_result.config.name,
        "version" => string(package_result.config.version),
        "julia_compat" => package_result.config.julia_compat,
        "load_check" => any(er -> loadable_on_load_check_agent(er.config.platform), collect_extractions(package_result)),
        "dependencies" => package_deps,
    ))
end

# Emit structured output that our caller can interpret.
# We use YAML because it already exists in the `.buildkite` project
YAML.write(stdout, groups)
