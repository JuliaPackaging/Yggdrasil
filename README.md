# Yggdrasil

Build Status: [![Build Status](https://dev.azure.com/JuliaPackaging/Yggdrasil/_apis/build/status/JuliaPackaging.Yggdrasil?branchName=master)](https://dev.azure.com/JuliaPackaging/Yggdrasil/_build/latest?definitionId=1&branchName=master)

![Yggdrasil](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Yggdrasil.jpg/430px-Yggdrasil.jpg)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

## Contributing

To contribute a new recipe, you can either

* use `BinaryBuilder.run_wizard()`, which will automatically open a pull request to this repository after a successfull build for all requested platforms
* Copy another build recipe using it as a template, and then open a manual pull request to this repository

Yggrasil builds the tarballs using `master` version of BinaryBuilder.jl, which requires Julia 1.3.0-rc4 or later versions.  Note that this BinaryBuilder.jl version has some differences compared to v0.1.4 and the builders generated are slightly different.  You are welcome to contribute builders written for  BinaryBuilder.jl v0.1.4, but they will likely need minor adjustements.

[Azure pipelines](https://dev.azure.com/JuliaPackaging/Yggdrasil/_build?view=runs) are used to test that the builders can successfully produce the tarballs.

If you prefer to test your manual buildscript before opening the pull request, we suggest installing `BinaryBuilder.jl` on Julia 1.3 and running `julia --color=yes build_tarballs.jl --verbose --debug` locally.  On MacOS, you will need to have `docker` installed for this to work.

## Using the generated tarballs

### JLL packages

The development version of BinaryBuilder makes use of the new [`Artifacts` system](https://julialang.github.io/Pkg.jl/dev/artifacts/) shipping in Julia 1.3.  This means that BinaryBuilder no longer generates `build.jl` files that are placed into your Julia package's `deps/` folder, but instead generates whole Julia packages (known colloquially as "jll" packages) that are placed within the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/).  Merged pull requests to Yggdrasil result in new versions of these wrapper packages being generated, uploaded and registered, allowing your client Julia code to simply invoke `using LibFoo_jll` to get ahold of your binaries with no need for a `Pkg.build()` step.  (This will, of course, only be the case for Julia 1.3+)

JLL packages created by Yggdrasil are hosted under the [JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers) GitHub organization and are automatically registered in the Julia package registry.  To add an dependency on a JLL file like [Cairo_jll](https://github.com/JuliaBinaryWrappers/Cairo_jll.jl) to your package, add a line `Cairo_jll = "83423d85-b0ee-5818-9007-b63ccbeb887a"` to the `[deps]` (dependencies) section of your `Project.toml` file.  The UUID of a JLL package (e.g. `83423d85-b0ee-5818-9007-b63ccbeb887a`) can be found by looking in the `Project.toml` of the JLL package under [JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers), for example in [`JuliaBinaryWrappers/Cairo_jll.jl/Project.toml`](https://github.com/JuliaBinaryWrappers/Cairo_jll.jl/blob/master/Project.toml) for Cairo_jll.

We encourage Julia developers to use JLL packages for their libraries.  Here are a few examples of pull requests switching to JLL package:

* [Cairo.jl](https://github.com/JuliaGraphics/Cairo.jl/pull/293)
* [FFTW.jl](https://github.com/JuliaMath/FFTW.jl/pull/122)
* [GSL.jl](https://github.com/JuliaMath/GSL.jl/pull/104)
* [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl/pull/447)
* [Rsvg.jl](https://github.com/lobingera/Rsvg.jl/pull/36)

You can read more about the `Artifacts` system and JLL packages and how they are important for reproducibility in this post on Julia's blog "[Pkg + BinaryBuilder -- The Next Generation](https://julialang.org/blog/2019/11/artifacts)".

### BinaryProvider.jl

We hope we convinced you about why it is important to switch to JLL packages.  However, if you really need to support Julia v1.2 or previous versions, you should keep using [BinaryProvider.jl](https://github.com/JuliaPackaging/BinaryProvider.jl).  As explained in the previous section, a `build.jl` file is not generated after the build anymore as that is not used for JLL packages, instead you would need to generate it yourself: In the top-directory of Yggdrasil there is a script to do this: [`generate_buildjl.jl`](./generate_buildjl.jl).  It takes three positional arguments:

* the path to the `build_tarballs.jl` script
* the `owner/name` of the repository where the tarballs have been uploaded.  If omitted, this defaults to `JuliaBinaryWrappers/BuilderName_jll.jl`
* the tag name where the tarballs have been uploaded.  If omitted, this defaults to the latest version of the JLL package in the [General registry](https://github.com/JuliaRegistries/General).  If there are no versions of the package in the registry, the script will fail.

For example, to get the `build.jl` file for the latest version of Zlib you can run the following command:

```
julia --color=yes generate_buildjl.jl Z/Zlib/build_tarballs.jl
```

If instead you want to get the `build_tarballs.jl` file for the tag named [Zlib-v1.2.11+6](https://github.com/JuliaBinaryWrappers/Zlib_jll.jl/releases/tag/Zlib-v1.2.11%2B6) you have to run the command

```
julia --color=yes generate_buildjl.jl Z/Zlib/build_tarballs.jl JuliaBinaryWrappers/Zlib_jll.jl Zlib-v1.2.11+6
```

*Note*: you have to manually add `prefix` as the first argument to all `Product` constructors in the generated `build.jl` files.  This is necessary because the syntax between `BinaryBuilder v0.2+` and `BinaryProvider` has diverged.

Remember that you will also need the `build.jl` files for all direct and indirect dependencies.

Here are a few examples of packages using this system to install their libraries:

* [Cairo.jl](https://github.com/JuliaGraphics/Cairo.jl/tree/15706f267cbb31da58f62270e46dc892c0c7ff9f/deps)
* [FFMPEG.jl](https://github.com/JuliaIO/FFMPEG.jl/tree/b6cca77f788e58409a13cac5ab6eaa6a5841b5c6/deps)
