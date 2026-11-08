---
name: testing-jll
description: How to build a Yggdrasil recipe locally and test the generated JLL before merging. Use when running build_tarballs.jl with --deploy=local or --debug, loading a locally built JLL, or testing tarballs from CI artifacts.
---

# Testing a JLL

Test the generated JLL before merging, so a broken package is not automatically registered in General.

On an x86_64 host (x86_64 macOS needs Docker), build one platform and deploy a local JLL:

```bash
cd X/PackageName
julia --project build_tarballs.jl --verbose --deploy=local x86_64-linux-gnu
```

This puts tarballs in `products/` and writes a local JLL package to `~/.julia/dev/PackageName_jll/`. The trailing triplet builds only that platform; omit it to build all of them. Use it for local testing only, never narrow `platforms` in the recipe to match. While iterating on a failing build, add `--debug` to drop into the sandbox shell on failure.

On other hosts (see [Prerequisites](../../../AGENTS.md#prerequisites)), push the branch, wait for the Buildkite jobs, and test the `products/*` tarballs from each job's Artifacts tab.

Load the JLL in a fresh environment. Each `ExecutableProduct` symbol becomes a function returning a `Cmd`:

```julia
using Pkg
Pkg.activate(; temp=true)
Pkg.develop(path=expanduser("~/.julia/dev/PackageName_jll"))
using PackageName_jll
run(`$(PackageName_jll.executable_name()) --version`)
```

Check that:

- [ ] The JLL imports without warnings or errors; this dlopens its libraries and their dependencies
- [ ] Executables run (at least `--version` or `--help`)
- [ ] Platform-specific behavior works, if any
- [ ] Packages that will use the JLL pass their tests with it (`Pkg.add` them to the same environment)
