# Yggdrasil

![Yggdrasil](https://user-images.githubusercontent.com/1282691/177174254-aa90664e-5c20-4ea3-9938-34de961dc198.png)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).

## Contributing

For detailed information about contributing, go to ["CONTRIBUTING.md"](https://github.com/JuliaPackaging/Yggdrasil/blob/master/CONTRIBUTING.md). For a quick overview, continue reading.

To update the version to build for an existing recipe, simply open a PR to this repository making the required tweaks. This can be as simple as updating the version number and the source (e.g. for github-hosted resources, update the URL and hash for an archive, or the revision for a repository) of the relevant `build_tarballs.jl` file. Note that in some cases more changes may be needed. A real example for updating the version of a github-hosted resource, see [this PR](https://github.com/JuliaPackaging/Yggdrasil/pull/8833). The version number should be easy to find, and the URL + hash can be found by clicking the release, clicking the final commit in the release, and copying the information from the URL bar.

To contribute a new recipe, you can either
* use `BinaryBuilder.run_wizard()`, which will automatically open a pull request to this repository after a successfull build for all requested platforms
* Copy another build recipe using it as a template, and then open a manual pull request to this repository

Yggdrasil builds the tarballs using `master` version of BinaryBuilder.jl, which requires Julia 1.3.0 or later versions.  Note that this BinaryBuilder.jl version has some differences compared to v0.1.4 and the builders generated are slightly different.  You are welcome to contribute builders written for  BinaryBuilder.jl v0.1.4, but they will likely need minor adjustements.

[Buildkite CI](https://buildkite.com/julialang/yggdrasil) is used to test that the builders can successfully produce the tarballs.

If you prefer to test your manual buildscript before opening the pull request, we suggest installing `BinaryBuilder.jl` on Julia 1.3 or any following release and running `julia --color=yes build_tarballs.jl --verbose --debug` locally.  On MacOS, you will need to have `docker` installed for this to work.

## Using the generated tarballs

### JLL packages

The last versions of BinaryBuilder make use of the [`Artifacts` system](https://julialang.github.io/Pkg.jl/dev/artifacts/) shipping in Julia 1.3.  This means that BinaryBuilder no longer generates `build.jl` files that are placed into your Julia package's `deps/` folder, but instead generates whole Julia packages (known colloquially as "jll" packages) that are placed within the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/).  Merged pull requests to Yggdrasil result in new versions of these wrapper packages being generated, uploaded and registered, allowing your client Julia code to simply invoke `using LibFoo_jll` to get ahold of your binaries with no need for a `Pkg.build()` step.  (This will, of course, only be the case for Julia 1.3+).

We encourage Julia developers to use JLL packages for their libraries.  Read the [documention of BinaryBuilder](https://juliapackaging.github.io/BinaryBuilder.jl/dev/jll/) to learn how to use them.

Here are a few examples of pull requests of Julia packages switching to using JLL package to provide the prebuilt binaries to the users:

* [Cairo.jl](https://github.com/JuliaGraphics/Cairo.jl/pull/293)
* [FFTW.jl](https://github.com/JuliaMath/FFTW.jl/pull/122)
* [GSL.jl](https://github.com/JuliaMath/GSL.jl/pull/104)
* [Gtk.jl](https://github.com/JuliaGraphics/Gtk.jl/pull/447)
* [Rsvg.jl](https://github.com/lobingera/Rsvg.jl/pull/36)

You can read more about the `Artifacts` system and how it is important for reproducibility in this post on Julia's blog "[Pkg + BinaryBuilder -- The Next Generation](https://julialang.org/blog/2019/11/artifacts)".

