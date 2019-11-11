# Yggdrasil

![Yggdrasil](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Yggdrasil.jpg/430px-Yggdrasil.jpg)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).  To contribute a new recipe, simply copy another build recipe using it as a template, and open a pull request to this repository.  It will be built, and binaries will be uploaded to GitHub releases.  At the moment, `@staticfloat` builds these binaries on-demand.

To test your buildscript, I suggest running `julia --color=yes build_tarballs.jl --verbose --debug` locally.  If running on a MacOS system, I suggest using the `docker`-based backend instead of the default QEMU backend by installing docker and exporting `BINARYBUILDER_RUNNER=docker` before invoking Julia.

Moving forward, BinaryBuilder is currently under heavy development to make use of the new [`Artifacts` system](https://julialang.github.io/Pkg.jl/dev/artifacts/) shipping in Julia 1.3.  Once that transition is finished, BinaryBuilder will no longer generate `build.jl` files that are placed into your Julia package's `deps/` folder, but will instead generate whole Julia packages (known colloquially as "jll" packages) that are placed within the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/).  Pull requests to Yggdrasil will thereafter result in new versions of these wrapper packages being generated, uploaded and registered, allowing your client Julia code to simply invoke `using LibFoo_jll` to get ahold of your binaries with no need for a `Pkg.build()` step.  (This will, of course, only be the case for Julia 1.3+)
