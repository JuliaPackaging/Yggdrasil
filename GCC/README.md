# GCCBuilder

[![Build Status](https://travis-ci.org/staticfloat/GCCBuilder.svg?branch=master)](https://travis-ci.org/quinnj/MbedTLSBuilder)

This repository builds binary artifacts for GCC.  This repository was created using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl)

## How to build this monstrosity

* First, run `global_warming.sh`.  This is just a wrapper bash script to compile the full combinatorial explosion of GCC versions and platforms that we support.  This should result in a huge number of tarballs in `products/` named things like `GCC.v4.9.4.x86_64-apple-darwin14.tar.gz` or `GCC.v8.1.0.i686-linux-musl.tar.gz`.

* If everything looks good, tag it.  I typically tag it with the highest GCC version built, followed by a "dash-revision", e.g. at the time of writing I would tag this as `v8.1.0-0`, and if I needed to make a rebuild of the same versions I would tag that as `v8.1.0-1`, etc...

* Next, run `make_buildjl_files.jl`.  This will read in each tarball, hash it, and group them by GCC version, emitting a `build.jl` file for each, which can be used to download and unpack a compiler for a particular version and platform.  It will then run `ghr` to upload all its products to the appropriate tag on GitHub.
