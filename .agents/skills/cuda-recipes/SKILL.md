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

- `CUDA.augment` delegates toolkit selection to `CUDA_Runtime_jll`. Its `version` preference overrides driver and GPU detection.
- From CUDA 11, `cuda=MAJOR.MINOR` matches a selected toolkit with the same major and an equal or newer minor. The highest matching artifact wins. Build with the oldest toolkit your code supports in each major, and add newer variants only when needed.
- No driver and no preference selects `none`. No matching artifact means `is_available() == false`. With a preference but no driver, the JLL loads and CUDA calls fail at run time.
- `CUDA.augment` rejects local toolkits. For JIT-only consumers, use `CUDA.compiler_augment` and a `CUDA_Compiler_jll` runtime dependency; compatible local toolkits can then match.

Recipe rules:

- **Name:** call a CUDA variant `PackageName_CUDA`, not `_GPU`.
- **Platforms:** use `CUDA.supported_platforms(; min_version, max_version)`, which covers Linux glibc x86_64 and aarch64. Bounds compare full SDK versions, so select one minor with `min_version=v"13.0", max_version=v"13.0.999"`. Before CUDA 13, aarch64 distinguishes Jetson and SBSA. Preview toolkits require `prereleases=true`.
- **Other OSes:** nvcc builds in BinaryBuilder cannot target Windows, musl or macOS. Windows vendor binaries can be repackaged.
- **Build loop:** skip with `should_build_platform(triplet(platform))`, then call `build_tarballs` once per platform. Get dependencies inside the loop with `CUDA.required_dependencies(platform; static_sdk=true)`. Omit the static SDK only when the build needs no static CUDA libraries.
- **Build arguments:** `augment_platform_block=CUDA.augment`, `lazy_artifacts=true`, `dont_dlopen=true`.
- **Direct driver linking:** use `LibraryProduct(...; dont_dlopen=true)` so the JLL imports without a driver. The `build_tarballs` option only skips build-time loading.
- **CPU builds:** tag CPU platforms with `cuda=none` where `CUDA.is_supported(platform)`, and branch on `${bb_full_target}`. `none` only matches when no toolkit is selected, not when the selected toolkit has no artifact.
- **MPI:** `MPI.augment` and `CUDA.augment` both define `preferences`, so wrap the latter in `module __CUDA` and call both from `augment_platform!`.
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

When testing preferences, add the JLL whose preferences you set (`CUDA_Runtime_jll` or `CUDA_Compiler_jll`) as a direct dependency of the test environment. Otherwise they are ignored.
