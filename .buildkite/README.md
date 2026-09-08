# Yggdrasil CI on Buildkite

Yggdrasil's CI is split across **two** Buildkite pipelines so that the secret
used to publish packages is never exposed to the (potentially untrusted)
`build_tarballs.jl` code that runs during a build.

```
                         ┌─────────────────────────────────────────────┐
   push / PR  ─────────► │  yggdrasil  (main pipeline)                  │
                         │                                              │
                         │  pipeline.yml                                │
                         │    └─ forerunner ─► generator.jl             │
                         │         dynamically uploads, per project:    │
                         │           • build_step   (one per platform)  │
                         │           • wait                             │
                         │           • trigger_registration_step ───────┼──┐
                         └──────────────────────────────────────────────┘  │
                                                                            │ trigger
                                                                            ▼
                         ┌──────────────────────────────────────────────┐
                         │  yggdrasil-register  (register pipeline)       │
                         │                                                │
                         │  register_pipeline.yml                         │
                         │    └─ register.sh ─► register_package.jl       │
                         │         publication secrets                    │
                         └────────────────────────────────────────────────┘
```

## Why two pipelines?

We moved off `cryptic-buildkite-plugin` to native [Buildkite
secrets](https://buildkite.com/docs/pipelines/security/secrets/buildkite-secrets).
Buildkite secrets are scoped per pipeline, so the tokens used to push `*_jll`
packages, create releases, and register packages
are readable **only** from the trusted `yggdrasil-register` pipeline.

The build steps run `build_tarballs.jl`, which is arbitrary code coming from
PRs. Those steps must never have access to publication tokens. By performing the
registration in a separate pipeline that is *triggered* (rather than running
the registration inline in the main pipeline), the tokens are only ever present
in the trusted registration job.


## `yggdrasil` — the main pipeline

* **WebUI step:** see [`0_webui.yml`](./0_webui.yml). It runs
  `buildkite-agent pipeline upload .buildkite/pipeline.yml`.
* [`pipeline.yml`](./pipeline.yml) uses the `JuliaCI/forerunner` plugin to
  detect which top-level project directories changed and runs
  [`generator.jl`](./generator.jl) for each of them.
* [`generator.jl`](./generator.jl) generates, per project, a group with a
  `build_step` per platform, a `wait`, and finally a
  `trigger_registration_step`. **The `trigger_registration_step` is only
  emitted for non-PR builds (i.e. on `master`); it is never added on PR
  builds.** PRs therefore build the tarballs to verify they compile, but never
  trigger the `yggdrasil-register` pipeline and never publish anything.
* The `build_step` and `trigger_registration_step` helpers live in
  [`utils.jl`](./utils.jl).
* Builds upload tarballs and their metadata sidecars as Buildkite artifacts.

## `yggdrasil-register` — the register pipeline

* This pipeline is only ever reached on `master`: the main pipeline emits the
  `trigger_registration_step` exclusively for non-PR builds, so a PR can never
  cause a registration.
* **WebUI step:** see
  [`0_webui_yggdrasil_register.yml`](./0_webui_yggdrasil_register.yml). It runs
  `buildkite-agent pipeline upload .buildkite/register_pipeline.yml`.
* [`register_pipeline.yml`](./register_pipeline.yml) runs
  [`register.sh`](./register.sh) inside a concurrency gate and declares both
  publication secrets.
* The triggering build supplies `NAME`, `PROJECT`, `SKIP_BUILD`, `BUILD_ID`
  (and the registry / pkg-server env) through the trigger step's `build.env`.
* `register.sh` regenerates the `meta.json` with both publication tokens cleared,
  starts Julia with multiple threads, and then runs
  [`.ci/register_package.jl`](../.ci/register_package.jl) with the tokens
  available.
* `register_package.jl` downloads the freshly-built tarballs and metadata from the
  triggering build with
  `buildkite-agent artifact download --build $BUILD_ID ...`, pushes the
  `*_jll` package, uploads the tarballs to GitHub releases, and registers the
  package to the General registry.

The register pipeline uses a global concurrency gate to keep at most three
registrations in flight. The registration step also has a per-package concurrency
group, so two builds cannot register the same JLL concurrently.

## Required Buildkite configuration

1. Create the `yggdrasil-register` pipeline (slug **`yggdrasil-register`** —
   the `trigger_registration_step` targets this exact slug).
2. Point its WebUI step at
   `buildkite-agent pipeline upload .buildkite/register_pipeline.yml`.
3. Add the `GITHUB_TOKEN` and `REGISTRY_GITHUB_TOKEN` Buildkite secrets and scope
   them so they are readable **only** by the `yggdrasil-register` pipeline.
