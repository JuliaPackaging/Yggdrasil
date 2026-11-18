---
name: cuda-recipes
description: Rules for Yggdrasil recipes that build CUDA code. Use when a build_tarballs.jl uses nvcc, includes platforms/cuda.jl or C/CUDA/common.jl, depends on CUDA_SDK_jll, CUDA_Runtime_jll, CUDA_Compiler_jll or CUDA_Driver_jll, or uses the cuda platform tag.
---

# CUDA packages

Copy `H/HelloWorldCUDA`. Helpers live in `platforms/cuda.jl` and `C/CUDA/common.jl`.

- `CUDA_SDK_jll`, `CUDA_SDK_static_jll`: build-only toolkit in `${prefix}/cuda`. nvcc links static CUDA libraries by default.
- `CUDA_Runtime_jll`: cudart, cupti, cublas, cufft, curand, cusolver, cusparse.
- `CUDA_Compiler_jll`: nvrtc, nvJitLink, nvvm, ptxas. Selected independently of the runtime.
- `CUDA_Driver_jll`: selects the system driver or NVIDIA's forward-compatibility driver.

Artifact selection:

- `CUDA.augment` delegates toolkit selection, and the fallback below, to `CUDA_Runtime_jll`, so its releases fix both for every JLL. Its `version` preference overrides driver and GPU detection.
- From CUDA 11, `cuda=MAJOR.MINOR` matches a selected toolkit with the same major and an equal or newer minor. Build with the oldest toolkit your code supports in each major. Add newer builds of a major only when needed: if several match, Base picks by comparing triplets as strings (13.9 over 13.10), not the newest.
- No driver and no preference selects `none`. A `version` preference selects CUDA builds even without a driver; CUDA calls then fail at run time.
- If no CUDA build matches the selected toolkit and the host's other tags (MPI ABI, architecture), the JLL selects its `cuda=none` build, or is unavailable (`is_available() == false`) without one.
- With a local toolkit (`local = "true"`), `CUDA.augment` rejects CUDA builds and selects the `cuda=none` build, if any. For JIT-only consumers, use `CUDA.compiler_augment` and a `CUDA_Compiler_jll` runtime dependency; compatible local toolkits can then match.

Recipe rules:

- **Name:** call a CUDA variant `PackageName_CUDA`, not `_GPU`.
- **CPU and CUDA builds of one package:** read [`variants.md`](variants.md): when to use one JLL or two, renaming, and what consumers check.
- **Platforms:** use `CUDA.supported_platforms(; min_version, max_version)`, which covers Linux glibc x86_64 and aarch64. Bounds compare full SDK versions, so select one minor with `min_version=v"13.0", max_version=v"13.0.999"`. Before CUDA 13, aarch64 distinguishes Jetson and SBSA. Preview toolkits require `prereleases=true`.
- **CUDA majors:** build for every major the code supports, CUDA 13 included, and say why when one is left out.
- **Other OSes:** nvcc builds in BinaryBuilder cannot target Windows, musl or macOS. Windows vendor binaries can be repackaged.
- **Build loop:** skip with `should_build_platform(triplet(platform))`, then call `build_tarballs` once per platform. Pass every call the same list from `CUDA.required_dependencies(platforms; static_sdk=true)`: the last call writes the JLL's Project.toml. It also sets the `CUDA_Runtime_jll` compat the hook needs (`CUDA.runtime_compat`); a recipe that declares `CUDA_Runtime_jll` itself must use that bound too, or its CUDA builds go unused next to an older `CUDA_Runtime_jll`. The first rebuild that raises this bound needs a new version, not just a build trigger. Omit the static SDK only when the build needs no static CUDA libraries.
- **Build arguments:** `augment_platform_block=CUDA.augment`, `lazy_artifacts=true`, `dont_dlopen=true`.
- **Direct driver linking:** use `LibraryProduct(...; dont_dlopen=true)` so the JLL imports without a driver. The `build_tarballs` option only skips build-time loading.
- **CPU builds in the same JLL:** add the CPU platforms through `CUDA.cpu_platforms`, which tags them `cuda=none`. Branch the script on `${bb_full_target}` (`*-cuda+[0-9]*` for CUDA builds).
- **MPI:** `augment_platform_block=CUDA.augment_with(MPI.augment, "augment_mpi!")`, which sets the CUDA tag last, as the fallback requires.
- **Architectures:** pass an explicit CMake list. `CUDA.cuda_gpu_archs(platform)` helps, but its table has no updates after CUDA 12.9. Omit `-real` on at least the newest architecture: its PTX is what runs on newer GPUs.
- **aarch64:** copy the example's x86_64 host-tool swap and cross-compiler setup. CUDA 13+ also needs the separate `libnvvm` archive. Remove the modified `${prefix}/cuda` before packaging.
- **Compiler:** CUDA 13's CCCL requires C++17. If upstream leaves the standard unset, GCC 11+ provides that default. This is not a blanket CUDA 13 requirement.
- **Vendor sources:** use `get_sources` from `C/CUDA/common.jl`, not hand-written archive URLs and hashes.

| Symptom | Fix |
|---|---|
| `cannot find -lcudart_static` or `-lcudadevrt` | Use `static_sdk=true` and `-DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"`: nvcc searches `lib64`, the SDK uses `lib` |
| Executable link fails on newer `GLIBC_*` symbols required by vendor libraries | Pass `-DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined"` |
| `cannot be dlopen()'ed`, then `Cannot continue with unsatisfied build products` | Pass `dont_dlopen=true` to `build_tarballs`: the build host may lack CUDA libraries |
| Audit cannot resolve `libcublas.so.13` | Expected: `CUDA_Runtime_jll` supplies it at run time |
| nvcc exhausts `/tmp` | Set `TMPDIR=${WORKSPACE}/tmpdir` and create it |
| Fresh install: `Artifact ... was not found` | Use `lazy_artifacts=true`: the first augmentation may not select an artifact |
| Newer GPU: `no kernel image is available for execution on the device` | Build an architecture without `-real` |
| JLL executable: `unsupported display driver / cuda driver combination` | It loaded a rejected compat driver from `LIBPATH`. Add `RuntimeDependency("CUDA_Driver_jll"; compat="13.3.6 - 13")` |

When testing preferences, add the JLL whose preferences you set (`CUDA_Runtime_jll` or `CUDA_Compiler_jll`) as a direct dependency of the test environment. Otherwise they are ignored. Before Julia 1.13, set `version` on both: changing only the runtime's preference doesn't invalidate `CUDA_Compiler_jll`'s cache, and `CUDA_Runtime_jll` then fails to load.
