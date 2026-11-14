---
name: reviewing-prs
description: What Yggdrasil reviewers check in a pull request, and how to post the review. Use when reviewing a Yggdrasil PR, and before opening or pushing one so it already passes these checks.
---

# Reviewing pull requests

These are the findings reviewers raise most often. Contributors: check your PR against them before opening it and after every push. Reviewers: go through them in order and post each finding on the line it concerns.

## Triage

PR-level findings go in the review body.

- **Stale**: a PR that is not a draft, was created more than a year ago, and has had no update for six months gets converted to a draft, with a comment, and no further review. Converting needs write access.

  ```bash
  gh pr view <N> -R JuliaPackaging/Yggdrasil --json createdAt,updatedAt,isDraft
  gh pr ready <N> -R JuliaPackaging/Yggdrasil --undo
  gh pr comment <N> -R JuliaPackaging/Yggdrasil -b "This PR has been open for over a year with no activity for six months, so I've marked it as a draft. Rebase it on master and mark it ready for review to continue."
  ```

  To find them all, with the dates one year and six months ago: `gh pr list -R JuliaPackaging/Yggdrasil --state open --search "draft:false created:<YYYY-MM-DD updated:<YYYY-MM-DD"`.
- **Version updates**: a PR that changes only `version` and the sources (URL, hash, `tag=`) gets the `merge me` label, so maintainers can merge it once CI passes: `gh pr edit <N> -R JuliaPackaging/Yggdrasil --add-label "merge me"`.
- **Scope**: one recipe and one version per PR, since several versions in one PR conflict in the registry. No edits to other recipes, the `.ci/` manifests, or non-recipe files ([Pull Requests](../../../AGENTS.md#pull-requests)).
- **Title**: `[Name] Brief description`, without noise such as "supersedes #N"; it becomes the squash commit message. The description says what changed and why, and links the upstream issue or General PR involved.
- **Rebase**: ask for one only for merge conflicts or to pick up a CI change. Rebase-only pushes rebuild for nothing ([Avoiding unnecessary rebuilds](../../../CONTRIBUTING.md#avoiding-unnecessary-rebuilds)).
- **Agent-written PRs**: the author checks the result against AGENTS.md and this checklist on current master before asking for review.
- **Pinging**: bump a PR gently, and only after answering every open comment.
- **Outside your expertise**: say so and cc the owner in `.github/component_owners.yml` or a known expert, rather than approving.

## Posting the review

Fetch the PR head to read files with the line numbers comments need, its CI status, and the comments already posted, which you don't repeat:

```bash
git fetch origin pull/<N>/head && git show FETCH_HEAD:X/Foo/build_tarballs.jl | cat -n
gh pr checks <N> -R JuliaPackaging/Yggdrasil
gh api repos/JuliaPackaging/Yggdrasil/pulls/<N>/comments --jq '.[] | "\(.user.login) \(.path):\(.line) \(.body)"'
```

Post all findings as one review:

```bash
jq -n --arg sha "$(gh pr view <N> -R JuliaPackaging/Yggdrasil --json headRefOid --jq .headRefOid)" '{
    commit_id: $sha,
    event: "COMMENT",
    body: "PR-level findings\n\nThis review was drafted by an AI agent.",
    comments: [
        {path: "X/Foo/build_tarballs.jl", line: 12, side: "RIGHT",
         body: "Please add `tag=\"v$(version)\"`, so the build checks the hash is the release."},
        {path: "X/Foo/build_tarballs.jl", start_line: 30, line: 32, side: "RIGHT",
         body: "```suggestion\nplatforms = supported_platforms()\n```"}
    ]
}' | gh api -X POST repos/JuliaPackaging/Yggdrasil/pulls/<N>/reviews --input -
```

- `line` is the line number in the PR's version of the file, and must be inside the diff. Put a finding about something missing on the nearest line, e.g. a missing `tag=` on the `GitSource` line. Findings about unchanged code or the whole PR go in `body`.
- Use a `suggestion` block when the fix is mechanical. A multi-line suggestion needs `start_line`, or it replaces only `line`; an empty one deletes the lines.
- Ask why about anything unexplained instead of guessing a reason.
- Use `COMMENT`: `REQUEST_CHANGES` blocks merging, auto-merge included, until that reviewer approves or the review is dismissed.
- Start a partial review with "Not a complete review".
- A review or comment drafted by an agent says so in its body, e.g. "This review was drafted by an AI agent."

## Checklist

Grouped by where the comment goes. Also apply every topic skill whose condition matches ([Skills](../../../AGENTS.md#skills)).

These are defaults: an exception is fine with a comment saying why and what would let it be removed ([Critical Rules](../../../AGENTS.md#critical-rules)). Reasons for the recipe as it stands go in comments; reasons for a change, such as a removed dependency, go in the PR description ([Style](../../../AGENTS.md#style)).

### `version`

- Latest upstream release; intermediate releases need not be packaged.
- Names an upstream release ([`jll-versioning`](../jll-versioning/SKILL.md)).
- The JLL version changes whenever the source commit or a compat bound, `julia_compat` included, changes. So does a renamed or removed product, or a new soname: a rebuild is not enough.

### `sources`

- Every `GitSource` in a recipe the PR touches has `tag=` and the tagged commit ([Sources](../../../AGENTS.md#sources)). The tag replaces comments such as `# v1.2.3`.
- The upstream repository, not a personal fork or branch, unless upstream is unmaintained and the fork carries it on ([Patches](../../../AGENTS.md#patches)). No GitHub `/archive/` URLs.
- Where a URL, tag or directory name can be computed from `version`, interpolate it instead of repeating the number ([Shell Script Conventions](../../../AGENTS.md#shell-script-conventions)). Leave literals that can't, such as the version of a separately released Windows binary.
- Sources come from `sources`, not from the script. Exceptions, each with a comment: `git clone --recurse-submodules` for many submodules, `apk add` of a build tool, and build systems that download their own dependencies, such as PETSc's.
- Where the project vendors a library Yggdrasil already builds, consider depending on its JLL instead ([Sources](../../../AGENTS.md#sources)).
- Build from source where possible. Upstream's prebuilt binaries, for some platforms or all, need a comment in `sources` saying why.

### Patches

- First line says what the patch does, followed by the upstream PR or issue; no unfilled placeholders ([Patches](../../../AGENTS.md#patches)).
- Has it been submitted upstream? The patch stays until an upstream release includes the fix. Don't hold the PR for upstream, which may release yearly or not care about a platform we support.
- One patch per independent fix.
- A compiler flag, not building tests, or disabling `-Werror` beats a patch when it suffices.
- A workaround for the toolchain itself, such as editing `${CMAKE_TARGET_TOOLCHAIN}` or `${MESON_TARGET_TOOLCHAIN}`, links the BinaryBuilderBase issue that would make it unnecessary.

### `script`

- No `sed`, `perl` or Python edits of sources outside the exceptions in [Patches](../../../AGENTS.md#patches).
- `install -Dvm`, `-v` on file commands, nothing hiding errors ([Shell Script Conventions](../../../AGENTS.md#shell-script-conventions)). No `if [ -f … ]` around installs: a missing file should fail the build.
- `install_license` for the project and every bundled one. When upstream ships no license file, install the standard text from the image, e.g. `install_license /usr/share/licenses/MIT`, instead of adding a copy to `bundled/`.
- No debugging residue, local-only switches or commented-out code ([Style](../../../AGENTS.md#style)).
- A workaround for one platform uses the narrowest condition that matches it: `x86_64-linux-musl*`, not `x86_64-*`, when only musl needs it.
- No soname or install_name flags, and no C++ standard flag overriding upstream's ([Shell Script Conventions](../../../AGENTS.md#shell-script-conventions)). `-shared` works on macOS too, so no separate `-dynamiclib` branch.
- The upstream build system where it works. When it doesn't, building by hand in the script, or with our own makefile, is fine with a comment saying why.
- Every unusual flag has a reason. CMake's warning "Manually-specified variables were not used" names `-D` options that have no effect; remove them.
- A newer macOS SDK through `require_macos_sdk` ([`macos-recipes`](../macos-recipes/SKILL.md)), not a hand-written `SDKROOT` block.
- Comments say only why: no narration of the code, no change history, no license headers, no references to AGENTS.md.

### `platforms`

- `supported_platforms()`, then one `filter!` per condition, each with a comment saying what breaks ([Platforms](../../../AGENTS.md#platforms)). Build as many platforms as possible.
- Dropping a platform the previous version shipped breaks the JLLs that depend on it there: do it only when it can no longer be built, and say so in the PR description.
- Exclusions copied from older recipes are often obsolete (riscv64, aarch64 FreeBSD, the Rust ones); try building them.
- Don't drop a whole OS to avoid one error; post the log and ask for help.
- Don't hold a PR for a niche platform: filter it with the error in the comment and follow up.

### `products`

- Every product on every platform it builds for ([Products](../../../AGENTS.md#products)).
- `dont_dlopen` has a comment saying why.
- `FileProduct` only for files a Julia package uses.

### `dependencies`

- `compat` on every `Dependency`, never removed or loosened, with a comment when it isn't obvious ([Dependencies](../../../AGENTS.md#dependencies)). The lower bound is the oldest compatible release that works, and exists for every platform built.
- No assumption that a dependency follows semver: check its recipe and #3024 ([Dependencies](../../../AGENTS.md#dependencies)).
- Stdlib JLL bounds agree with `julia_compat` ([Dependencies](../../../AGENTS.md#dependencies)).
- A positional version only when needed, equal to the lower bound.
- `BuildDependency` and `HostBuildDependency` take no `compat`; pin one with `PackageSpec(; name="X_jll", version="1.2.3")` only when the build needs that version.
- Headers or a static library used only at build time make a `BuildDependency`; ask why a library is linked statically. A JLL built for `AnyPlatform()` usually is one.
- The image has CMake: `HostBuildDependency` on `CMake_jll` only when the build needs a newer CMake, pinned to the version it needs, e.g. `HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.31.9"))`.
- When a dependency is removed, the PR description says why. Check the log that configure doesn't still look for it and silently disable features.

### `build_tarballs` keywords

- `preferred_gcc_version` and `preferred_llvm_version` only when required, to the oldest version that works, with a comment saying why ([GCC Version Selection](../../../AGENTS.md#gcc-version-selection)).
- `julia_compat` is the oldest Julia the JLL works on. It must be raised when a dependency or a stdlib JLL needs a newer Julia; any other raise needs a reason, e.g. matching the Julia package that uses the JLL.
- No unneeded keywords.

### CI and testing

- Every platform builds, and the log is clean too: no missing license, no "could not be resolved and could not be auto-mapped" ([Information for maintainers](../../../CONTRIBUTING.md#information-for-maintainers)), no dependency configure failed to find, and the installed files show in it.
- The JLL was tested, also on the oldest Julia that `julia_compat` admits ([`testing-jll`](../testing-jll/SKILL.md)).
- After merging, the registration PR in General is watched until it merges ([Testing](../../../AGENTS.md#testing)).
