# This script is meant to run a simple test of the BB2 Yggdrasil build integration
using YAML

# Mark ourselves as a pull request by default.  The `git branch` thing
# is so that `generator.jl` can get a commit message for this fictitious pull request.
ENV["BUILDKITE_PULL_REQUEST"] = "-1"
run(`git branch -f origin/pr/-1`)

YGGDRASIL_BASE = dirname(dirname(@__DIR__))

# Load YAML definition of buildkite job
yaml = YAML.load(readchomp(
    Cmd(`$(Base.julia_cmd()) --project .buildkite/generator.jl H/HelloWorldCxx`;
        dir=YGGDRASIL_BASE
    )
))

function run_buildkite_cmd(cmd)
    env = copy(ENV)
    env["JULIA_PROJECT"] = @__DIR__
    return run(Cmd(`/bin/bash -c $(cmd)`; dir=YGGDRASIL_BASE, env))
end

# We're going to "upload" our build products to this archive folder
# This also preserves the artifacts from our `clean_products.sh` script
archive_dir = joinpath(YGGDRASIL_BASE, "archive")
mkpath(archive_dir)

# Run all the build steps
for bk_group in yaml["steps"]
    for bk_step in bk_group["steps"]
        continue
        if !startswith(bk_step["label"], "build")
            continue
        end

        for cmd in bk_step["commands"]
            @info(bk_step["label"])
            run_buildkite_cmd(cmd)

            # Now, "upload those builds"
            products_dir = joinpath(YGGDRASIL_BASE, bk_group["group"], "products")
            for file in readdir(products_dir)
                @info("Upload: ", file)
                mv(joinpath(products_dir, file), joinpath(archive_dir, file))
            end
        end
    end
end

# Now we're going to run the register steps
for bk_group in yaml["steps"]
    for bk_step in bk_group["steps"]
        if !startswith(bk_step["label"], "register")
            println("skipping $(bk_step["label"])")
            continue
        end

        # "download" the artifacts
        products_dir = joinpath(YGGDRASIL_BASE, bk_group["group"], "products")
        for file in readdir(archive_dir)
            @info("Download: ", file)
            cp(joinpath(archive_dir, file), joinpath(products_dir, file))
        end

        # Run registration
        for cmd in bk_step["commands"]
            @info(bk_step["label"])
            run_buildkite_cmd(cmd)
        end
    end
end


# Cleanup our fake branch
run(`git branch -d origin/pr/-1`)
