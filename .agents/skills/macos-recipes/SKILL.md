---
name: macos-recipes
description: Rules for Yggdrasil recipes that need a newer macOS SDK or deployment target. Use when a build fails only on macOS, or a build_tarballs.jl calls require_macos_sdk, includes platforms/macos_sdks.jl, or sets MACOSX_DEPLOYMENT_TARGET, SDKROOT or -mmacosx-version-min.
---

# macOS SDK and deployment target

The SDK decides which headers and library symbols the build sees. The deployment target (`MACOSX_DEPLOYMENT_TARGET`) is the oldest macOS the binary loads on; libc++ rejects features introduced after it.

By default, `x86_64-apple-darwin` builds against SDK 10.12 with deployment target 10.10. `aarch64-apple-darwin` builds against SDK 11.1, and arm64 macOS starts at 11.0, so it already has everything up to 11.0.

## When

Request a newer SDK only to fix a macOS build failure caused by the default SDK, typically on x86_64:

```text
error: 'path' is unavailable: introduced in macOS 10.15
```

or a declaration or symbol the default SDK lacks, such as `aligned_alloc`. Never add it as a precaution, by analogy with another recipe, or to fix a failure on another OS.

Recipes linking `LLVM_full_jll` need SDK 10.14 for LLVM 15 to 21 and 11.0 for LLVM 22 and later, matching what `L/LLVM/common.jl` builds LLVM with.

## How

```julia
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# std::filesystem needs macOS 10.15
sources, script = require_macos_sdk("10.15", sources, script)
```

- **Version**: the lowest that fixes the build, i.e. the one the "introduced in macOS X" error names. Say in the comment which feature needs it.
- **Placement**: after `sources` and `script` are final, before `build_tarballs`. It appends the SDK tarball to `sources` and prepends its setup to `script`.
- **Scope**: up to 11.1 it changes only `x86_64-apple-darwin`; above 11.1 it changes both macOS targets. Other platforms download the tarball but don't unpack it.
- **Available versions** are the keys of `macos_sdk_sources` in `platforms/macos_sdks.jl`. To use another, add it there in a separate PR first; don't add entries from a recipe.

## Deployment target

`deployment_target` defaults to the SDK version, so `require_macos_sdk("10.15", …)` also drops support for macOS before 10.15. When the newer SDK is needed only for headers, e.g. C++20 library headers from SDK 14.0 in code whose runtime needs stop at 10.15, keep the target lower:

```julia
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="10.15")
```

If the target is too low, the build fails with "introduced in macOS X" again; raise it to that X.

## Don't

- Set `MACOSX_DEPLOYMENT_TARGET`, `SDKROOT` or `-mmacosx-version-min` by hand, or unpack an SDK or edit the sys-root yourself. The helper also rewrites the CMake and Meson toolchain files and the compiler wrappers, which hand-rolled setups miss.
- Copy the SDK setup of recipes that do any of this; they predate the helper.
