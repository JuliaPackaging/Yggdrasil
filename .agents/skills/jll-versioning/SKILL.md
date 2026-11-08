---
name: jll-versioning
description: Yggdrasil rules for JLL version numbers. Use when a recipe needs a JLL version different from the upstream version (ygg_version), when a compat bound or ABI-breaking dependency change forces a new JLL version, or when the upstream version string is not plain X.Y.Z (non-semver, "2.8", four components).
---

# Upstream and JLL Versions

`version` names the upstream release: URLs, tags, and versioned library names derive from it. When the JLL needs a different version, keep `version` and add `ygg_version`, which is what `build_tarballs` gets:

```julia
version = v"1.6.0"
ygg_version = v"1.6.1"  # Comment on why the JLL version differs from upstream

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies)
```

Use this when:

- A rebuild must get a new JLL version rather than a new build number, e.g. because a compat bound changed (see [Dependencies](../../../AGENTS.md#dependencies)) or a dependency moved to a new ABI-breaking release.
- Upstream does not use semantic versioning, e.g. map upstream `20U4` to `ygg_version = v"2.0.400"`.

Every new `ygg_version` must exceed all registered versions of the JLL, and downstream compat bounds refer to `ygg_version`, not to upstream. Bumping the patch (`1.6.0` → `1.6.1`) collides with upstream's next patch release: when upstream releases `1.6.1`, the JLL needs `ygg_version = v"1.6.2"`. Drop `ygg_version` once `version` is larger than every registered JLL version again. Recipes that rebuild often reserve room instead:

```julia
version = v"2.2.3"
offset = 1  # bump for rebuilds, reset on a new upstream release
ygg_version = VersionNumber(version.major, version.minor, 100 * version.patch + offset)
```

Keep whatever scheme the recipe already uses; switching back would make the JLL version go down.

When the upstream spelling of a version can't be recovered from a `VersionNumber` (e.g. `"2.8"` prints as `2.8.0`), keep the upstream string and derive `version` from it, so the version literal appears only once:

```julia
version_string = "2.8"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gsl/gsl-$(version_string).tar.gz", "sha256"),
]
```

Interpolate `version_string` into URLs, tags, and directory names, and `version` everywhere a `VersionNumber` is needed. Existing recipes call it `version_string` or `version_str`; follow the recipe at hand. The two mechanisms combine: `version_string = "2.8"` with `ygg_version = v"2.8.1"`. Upstream versions with four or more components (`"2.1.12.5"`) do not parse as a `VersionNumber`, so set `version` by hand instead.
