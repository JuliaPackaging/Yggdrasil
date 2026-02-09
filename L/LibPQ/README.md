## LibPQ build notes

### Build and download tarballs

You can build tarballs in your fork CI and download them from the workflow artifacts.

1. Enable GitHub Actions on your fork.
2. Run the **LibPQ CI (fork only)** workflow.
3. Open the workflow run and download the `libpq-products` artifact.
4. Extract it and place the tarballs under `L/LibPQ/products/`.

### Create a local LibPQ_jll

These steps create a local `LibPQ_jll` from prebuilt tarballs (for example, from fork CI artifacts).

1. Put the downloaded tarballs in `L/LibPQ/products/`.
2. Run a local deploy using the `.ci` project and skip building:

```bash
cd L/LibPQ
julia --project=../../.ci build_tarballs.jl --skip-build --deploy=local \
	x86_64-linux-gnu aarch64-linux-gnu aarch64-apple-darwin x86_64-w64-mingw32
```

This writes the JLL wrapper to `~/.julia/dev/LibPQ_jll/`.

3. Use it in a test environment:

```julia
using Pkg
Pkg.activate(mktempdir())
Pkg.develop(path=expanduser("~/.julia/dev/LibPQ_jll"))
Pkg.add("LibPQ")
using LibPQ
```

If you only have Linux tarballs, remove the macOS and Windows targets from the command.
