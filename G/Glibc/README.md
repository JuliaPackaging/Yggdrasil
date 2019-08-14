# GlibcBuilder

[![Build Status](https://gitlab.com/BinaryBuilder.jl/GlibcBuilder/badges/master/pipeline.svg)](https://gitlab.com/BinaryBuilder.jl/GlibcBuilder/pipelines)

This repository builds binary artifacts for Glibc. Binary artifacts are automatically uploaded to
[this repository's GitHub releases page](https://github.com/staticfloat/GlibcBuilder/releases) whenever a tag is created
on this repository.

This repository was created using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl)

Because we tend to use different versions of `glibc` on different architectures, this repository has multiple versions built as a part of each release, each supporting a different subset of platforms.  We recommend using the oldest version possible for the architecture you are interested in.
