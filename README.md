# Yggdrasil

![Yggdrasil](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Yggdrasil.jpg/430px-Yggdrasil.jpg)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

## Contributing

To contribute a new recipe, you can either

* use `BinaryBuilder.run_wizard()`, which will automatically open a pull request to this repository after a successfull build for all requested platforms
* Copy another build recipe using it as a template, and then open a manual pull request to this repository

[Azure pipelines](https://dev.azure.com/JuliaPackaging/Yggdrasil/_build?view=runs) are used to test that the builders can successfully produce the tarballs.

If you prefer to test your manual buildscript before opening the pull request, we suggest installing `BinaryBuilder.jl` on Julia 1.3 and running `julia --color=yes build_tarballs.jl --verbose --debug` locally.  On MacOS, you will need to have `docker` installed for this to work.

## Using JLL packages

The development version of BinaryBuilder makes use of the new [`Artifacts` system](https://julialang.github.io/Pkg.jl/dev/artifacts/) shipping in Julia 1.3.  This means that BinaryBuilder no longer generates `build.jl` files that are placed into your Julia package's `deps/` folder, but instead generates whole Julia packages (known colloquially as "jll" packages) that are placed within the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/).  Merged pull requests to Yggdrasil result in new versions of these wrapper packages being generated, uploaded and registered, allowing your client Julia code to simply invoke `using LibFoo_jll` to get ahold of your binaries with no need for a `Pkg.build()` step.  (This will, of course, only be the case for Julia 1.3+)
