# LLVMBuilder

[![Build Status](https://travis-ci.org/staticfloat/LLVMBuilder.svg?branch=master)](https://travis-ci.org/staticfloat/LLVMBuilder)

This is an example repository showing how to construct a "builder" repository for a binary dependency.  Using a combination of [`BinaryBuilder.jl`](https://github.com/staticfloat/BinaryBuilder.jl), [Travis](https://travis-ci.org), and [GitHub releases](https://docs.travis-ci.com/user/deployment/releases/), we are able to create a fully-automated, github-hosted binary building and serving infrastructure.

### Tips and tricks

1. Add `BINARYBUILDER_USE_CCACHE=true` to your environment to speed up rebuilds
2. Besides the usual BinaryBuilder commandline flags `build_tarball.jl` also supports
  1. `--llvm-release` Only build a release build
  2. `--llvm-debug` Only build a debug build
  3. `--llvm-keep-tblgen` Keep tblgen around for later builds
  3. `--llvm-check` Run unit tests
3. Use [ghr](https://github.com/tcnksm/ghr) or similar to upload builds to github
