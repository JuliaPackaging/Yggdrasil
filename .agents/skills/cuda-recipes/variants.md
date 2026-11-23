# Packages with CPU and CUDA builds

How to package a library that has CPU and CUDA builds, and how a Julia package consumes
them. [`SKILL.md`](SKILL.md) covers the build mechanics.

## How selection works

Unless the platform already has a `cuda` tag, `CUDA.augment` gives the host the tag of
the toolkit CUDA_Runtime_jll selects:
- **With an NVIDIA driver:** `cuda=X.Y`, chosen from the driver and its GPUs, or from
  the driver alone when no GPU is usable (login nodes, `CUDA_VISIBLE_DEVICES=""`).
- **Without a driver:** `cuda=none`, unless a `version` preference pins a toolkit.
- **Local toolkit** (`local = "true"`): `cuda=none` for this JLL.
- **No CUDA build for that toolkit** and the host's other tags (MPI ABI, architecture):
  `cuda=none`.

With `cuda=none`, the JLL loads its CPU build, or is unavailable
(`is_available() == false`) if it has none. The selection is fixed when the JLL is
precompiled. Pkg downloads the selected build at install time, even with
`lazy_artifacts=true`. If CUDA_Runtime_jll can't load yet during installation, Pkg
selects the CPU build, if any, and the CUDA build is downloaded at first load.

## Choose a layout

- **The project has no CPU build** (CUDSS, cuTENSOR, AMGX): one JLL with only CUDA
  builds.
- **The project can build its CUDA code as separate libraries next to the CPU library**
  (SCS_GPU; ONNX Runtime with `onnxruntime_BUILD_CUDA_EP_AS_PLUGIN`): `Foo_jll` keeps
  the CPU build, and `Foo_CUDA_jll` holds only the CUDA libraries, whether the library
  itself or the consumer loads them. See [Extra CUDA libraries](#extra-cuda-libraries).
  Nothing is renamed, `Foo_jll` is the same for every user, and another GPU backend is
  another JLL. Prefer this layout whenever upstream offers such a build. A patch
  carrying an open upstream PR is fine, but don't restructure a monolithic build in
  Yggdrasil.
- **Otherwise, the question is: can the CUDA build substitute for the CPU build
  wherever it is selected, including without a usable GPU?**
  - Yes (LAMMPS, HeFFTe): one JLL with `cuda=none` and `cuda=X.Y` builds. This is
    the default for CUDA code compiled into the library.
  - No: a separate `Foo_CUDA` JLL next to `Foo_jll` with the full CUDA build, with
    renamed libraries. See [Full CUDA build in a separate JLL](#full-cuda-build-in-a-separate-jll).

The CUDA build can't substitute when:
1. **The CPU library must stay loaded.** SuiteSparse_GPU can't replace the stdlib's
   `libcholmod`.
2. **Products or build variants are missing.** PETSc_CUDA builds two of PETSc_jll's
   nine variants. Extra products are fine.
3. **It needs something CPU users lack:** it fails without a usable GPU, initializes
   CUDA when loaded, or requires CUDA-aware MPI.
4. **Its ABI differs and other binaries link it.** SuperLU_DIST's `GPU_ACC` changes
   public structs, and PETSc_jll links it. An ABI difference only Julia code sees is
   fine: the consumer picks its bindings by build.
5. **It makes CPU use measurably worse:** slower code or loading, or more memory.

Narrower toolkit, architecture or MPI coverage is no reason to split: hosts without a
matching CUDA build get the CPU build. Neither is download size.

## One JLL with CPU and CUDA builds

Recipe (`H/HelloWorldCUDA` is the example):
- Platforms: `[CUDA.cpu_platforms(platforms); CUDA.supported_platforms(; ...)]`.
- The CUDA build keeps the CPU build's products and library names, and may add
  products. Only one of the two is ever loaded.
- Dependencies with `cuda` tags must have the same ABI in their CPU and CUDA builds,
  since a dependency may select its CUDA build where this JLL falls back to its CPU
  build. Every release within the compat bound must keep the toolkits this JLL was
  built against.

Consumer: depend on the JLL.
- `Foo_jll.host_platform["cuda"] == "none"` means the CPU build was loaded, also on a
  GPU host. Use it to pick bindings where the builds differ.
- To get the CUDA build for another toolkit, pin one the JLL has a build for, for the
  whole environment, e.g. `CUDA.set_runtime_version!(v"12.9")`.
- With a local toolkit, a wrapper that prefers a local library checks
  `get(tags(Foo_jll.host_platform), "cuda_local", "false") == "true"`.

## GPU-only JLL

Recipe: only CUDA platforms. A host without a matching build gets nothing, so cover
every CUDA major your consumers support.

Consumer: check `CUDA.functional()`, then `Foo_jll.is_available()`.

## Extra CUDA libraries

Recipe: `Foo_CUDA_jll` ships only the CUDA libraries. If they link the core library,
depend on `Foo_jll` with an exact bound (`compat="=1.2.3"`) instead of shipping a copy,
and release both together: consumers depend on both, so an outdated `Foo_CUDA_jll` holds
`Foo_jll` back for everyone.

Consumer: depend on both JLLs, and use the CUDA libraries when
`Foo_CUDA_jll.is_available()` and, if they need a GPU, `CUDA.functional()`. Put methods
taking `CuArray`s in a package extension on CUDA.jl. It reaches `Foo_CUDA_jll` through
the parent package, since extensions can't have dependencies of their own.

## Full CUDA build in a separate JLL

Recipe:
- Put shared sources, script and products in `common.jl`, with one directory per JLL
  (`O/OpenCV/OpenCV`, `O/OpenCV/OpenCV_CUDA`). Changing only `common.jl` rebuilds
  nothing: bump `# Build trigger` in the recipes that should change.
- **Rename the libraries** with a `_cuda` suffix. Both JLLs can be loaded in one
  process, and binaries linking a SONAME both copies share can bind to the wrong one.
  Only a library that no binary links, loaded by path from Julia alone, can keep its
  name.
  - Rename through the build system, so that the SONAME and every reference to it
    change together: `-DCMAKE_RELEASE_POSTFIX=_cuda` (SuiteSparse_GPU),
    `-DOPENCV_DLLVERSION=_cuda` (OpenCV), `SUPERLU_SUFFIX` (SuperLU_DIST_CUDA).
  - Without such an option, for ELF: rename the files, run `patchelf --set-soname` on
    each, and `patchelf --replace-needed` on every library and executable linking them.
  - Keep the product symbols: `LibraryProduct("libfoo_cuda", :libfoo)`.
- **Dependencies:** link a split dependency's `Foo_CUDA` library, and a default-layout
  dependency as is.
- **CPU libraries shared on purpose** (SuiteSparse_GPU links the stdlib's
  `libsuitesparseconfig`): pin them exactly, and check what each supported Julia
  version ships, since compat on a stdlib JLL is not enforced.

Consumer: depend on both JLLs, and pick one copy at load time, not in a top-level
`const`, which would record the GPU of the host that precompiled the package. Drop
`CUDA.functional()` if the CUDA build works without a GPU:

```julia
libfoo::String = ""
function __init__()
    use_cuda = Foo_CUDA_jll.is_available() && CUDA.functional()
    global libfoo = use_cuda ? Foo_CUDA_jll.libfoo_path : Foo_jll.libfoo_path
end
```

Select the bindings the same way when the ABIs differ. A switch to force the CPU build
belongs to the consumer package, not to the JLLs.

## Changing an existing JLL

Renaming libraries or changing a build's ABI breaks dependents built against the old
one, and their compat bounds usually admit the new release. Release it as a new
version, since compat ignores build numbers, and rebuild every dependent with its
compat raised to that version. Also cap the bound of the dependents' older releases in
General, so that they exclude the new version. Adding CPU builds to a GPU-only JLL
needs none of this when the CUDA builds are unchanged, but it still needs a new version
when it raises the `CUDA_Runtime_jll` bound.

## Testing

Besides [`testing-jll`](../testing-jll/SKILL.md), on a GPU host:
- **Default:** the consumer uses the CUDA build. With a split, load both JLLs in both
  orders, each in a fresh process, and exercise a dependent: check the loaded paths
  (`Libdl.dllist()`) and that each dependent calls into the intended copy.
- **Fallback:** with CUDA_Runtime_jll and CUDA_Compiler_jll as direct dependencies, pin
  both to a toolkit with no compatible build in the JLL (a newer minor still matches an
  older build). Expect the CPU build, or no artifact for a GPU-only JLL. Then pin a
  toolkit the JLL has a build for, add `local = "true"`, and expect the same.
- **No driver:** mask it, and use a fresh depot without `version` preferences. Expect
  the CPU build, or no artifact for a GPU-only or `Foo_CUDA` JLL:

  ```sh
  bwrap --dev-bind / / --ro-bind /dev/null /usr/lib/libcuda.so.<version> julia ...
  ```

- **Substitution:** run the consumer's CPU tests against the CUDA build, with and
  without `CUDA_VISIBLE_DEVICES=""`.
