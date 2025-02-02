The Care and Feeding of a Root Filesystem
=========================================

This document details some of the journey we have embarked upon to create a Linux environment that supports cross-compilation for a very wide range of architectures and platforms.  At the moment of writing, we support the following platforms (expressed in compiler triplet format):

* glibc Linux: `i686-linux-gnu`, `x86_64-linux-gnu`, `aarch64-linux-gnu`, `armv7l-linux-gnueabihf`, `armv6l-linux-gnueabihf`, `powerpc64le-linux-gnu`, `riscv64-linux-gnu`
* musl Linux: `i686-linux-musl`, `x86_64-linux-musl`, `aarch64-linux-musl`, `armv7l-linux-musleabihf`, `armv6l-linux-musleabihf`
* MacOS: `x86_64-apple-darwin`, `aarch64-apple-darwin`
* FreeBSD: `x86_64-unknown-freebsd13.4`, `aarch64-unknown-freebsd13.4`
* Windows: `i686-w64-mingw32`, `x86_64-w64-mingw32`

These target platforms are compiled for by building a suite a cross-compilers (`gcc`, `gfortran`, `clang`, `binutils`, etc...) that run on `x86-64-linux-musl`, but target the specific platform.  Unfortunately, it is not sufficient to simply build these compilers once per target, because of incompatibilities between the generated code and the user's system where this code may eventually be running.

The RootFS
==========

Our Linux environment is based upon Alpine linux, due to its small overhead, single-user nature, and because we enjoy the challenge of building all our native tools against `musl`.  It builds character.  Most native tools are installed directly through `apk`, with the notable exception of compilers such as `GCC` and `clang`, which we compile ourselves directly, as explained below.

Sources of incompatibility
==========================

There are multiple sources of incompatibility that can prevent binaries from being portable.  Here is the list of all incompatibility sources we explicitly deal with, and how we address them:

* `libc`: As most support libraries, eventually, depend on C, the C support library must contain the necessary symbols to support whatever calls are made against it from the compiled object.  To ensure this, we build against the oldest version of the C runtime as possible within BinaryBuilder.  On most systems, this simply means compiling against an SDK from an old OS release, on Linux this means compiling against old versions of `glibc`/`musl`.
* `libstdc++`: For projects that use C++, we have the same problem as with `glibc`.  The versioning of `libstdc++`, however, is locked to the version of `g++` used to compile the object code.  This would be a problem, except for the fact that the `g++` team has done an excellent job of never breaking backward-compatibility, and so we simply ship a very recent `libstdc++` alongside Julia/within the BinaryBuilder environment, and we never have to worry about this.  (The excellent news is that, due to the good backwards compatibility, we never have to worry about a newer `libstdc++` breaking code on the user's computer).
* `libgfortran`: For projects that use Fortran, we need to worry about the large ABI-breaking changes made in GCC 4, GCC 7 and GCC 8.  These breaking changes led to the SONAME of `libgfortran` changing, meaning that code compiled by `gfortran4` is not runnable on a system that uses `gfortran7` natively.  To deal with this, we simply have no other choice but to compile all Fortran code `N` times, where `N` is the number of `libgfortran` versions we wish to support.
* `cxx11`: The [C++11 String ABI changes](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) caused C++ code compiled by GCC 5+ to become incompatible with C++ code compiled by GCC 4-, but with compile-time switches available (`-D_GLIBCXX_USE_CXX11_ABI=0`) to enable compatibility again with later compilers, which is turned on by some distro compilers.
* `binutils`: Using too new of a `binutils` can cause static libraries to be unusable by older `ld` versions.  To deal with this, we use a `binutils` version that is appropriate for the GCC version in use.
* `clang`: No incompatibilities known.  <3

`glibc` Versions
================

The version of `glibc` we can compile against varies by system; we attempt to use the earliest version that will compile against a specific architecture and all our GCC versions, which works out to the following table:

| Architecture | `glibc` |
|--------------|---------|
|    x86_64    | v2.17   |
|     i686     | v2.17   |
|    aarch64   | v2.19   |
|     armv7l   | v2.19   |
|  powerpc64le | v2.17   |
|    riscv64   | v2.35   |


Compiler Shards
===============

To deal with the above sources of incompatibility, we compile the following shards:

* `clang` (one shard for all targets)
* `GCC+binutils`, split by version according to the following table:

    | GCC    | Binutils | libgfortran SONAME | libstdc++ SONAME    | string ABI |
    |--------|----------|--------------------|---------------------|------------|
    | 4.8.5  | 2.24     | libgfortran.so.3   | libstdc++.so.6.0.19 | cxx03      |
    | 5.2.0  | 2.25.1   | libgfortran.so.3   | libstdc++.so.6.0.21 | cxx11      |
    | 6.1.0* | 2.26     | libgfortran.so.3   | libstdc++.so.6.0.22 | cxx11      |
    | 7.1.0  | 2.27     | libgfortran.so.4   | libstdc++.so.6.0.23 | cxx11      |
    | 8.1.0  | 2.31     | libgfortran.so.5   | libstdc++.so.6.0.25 | cxx11      |
    | 9.1.0  | 2.33.1   | libgfortran.so.5   | libstdc++.so.6.0.26 | cxx11      |
    | 10.2.0 | 2.34     | libgfortran.so.5   | libstdc++.so.6.0.28 | cxx11      |
    | 11.1.0 | 2.36     | libgfortran.so.5   | libstdc++.so.6.0.29 | cxx11      |
    | 12.1.0 | 2.38     | libgfortran.so.5   | libstdc++.so.6.0.30 | cxx11      |
    | 13.2.0 | 2.41     | libgfortran.so.5   | libstdc++.so.6.0.32 | cxx11      |

Our GCC version selection is informed by two requirements: the `libgfortran` and `cxx11` incompatibilities.  First off, we must select compiler versions that span the three `libgfortran` SONAMEs we support, and we choose the oldest possible compilers within each SONAME bucket, yielding GCC `4.8.5`, `7.1.0` and `8.1.0`.  We choose the oldest possible GCC version so as to maximize the chance that C++ code compiled via this shard will be portable on other user's systems even without Julia's bundled `libstdc++.so`.  Next, we must provide a way for a user that is on a system with cxx11-defaulted strings but still using `libgfortran.so.3` (this would be the case if they were using GCC 5.3.1, for example, as Ubuntu 16.04 does) to link against our C++ code, so we add `5.2.0` in as the oldest 5.X.0 version that compiles on all our platforms, links against `libgfortran.so.3`, and defaults to `cxx11` string ABI.

We also compile `GCC 6.1.0` because we have had a report of at least one piece of software that refuses to build with anything older, but also contains Fortran code, and so we needed something that would work on `libgfortran.so.3` systems.  We include it here as part of the build, but it is somewhat "hidden" from the user, and will never be used to compile automatically, it must be manually selected.  This is done by providing the `preferred_gcc_version` keyword argument to `build_tarballs.jl`.  Note that you cannot select an "illegal" version of `gcc` using this parameter; setting a libgfortran requirement will lock you to certain valid versions, and the true version of GCC chosen will merely be the closest possible to the "preferred" version.

Expanded triplet naming convention
==================================

To disambiguate systems and build products across these dimensions of incompatibility, we have extended the platform target "triplet" concept to include tags for libgfortran ABI version and cxx11 string ABI choice.  A typical Ubuntu Xenial machine may therefore be fully identified by the triplet `x86_64-linux-gnu-gcc7-cxx11`, whereas a MacOS Mojave system may be identified by `x86_64-apple-darwin14-gcc8-cxx03`.  Note that the tag format `-gccN` was an unfortunately short-sighted choice to refer to `libgfortran` compatibility version, and that future versions of tools will support both `-gcc8` as well as the equivalent `-libgfortran5` tag format.  An (increasingly inaccurately named) triplet therefore fully specifies a given system, as well as a given build product.

Not all software must be compiled for the full combinatorial explosion of (platform, libgfortran version, cxx11 ABI).  Many pieces of software can be compiled once per platform, and to signify that they do not depend on a particular `libgfortran` version or cxx11 ABI, they will simply lack those tags.  The consuming software must therefore match a particular host platform against a variety of possibly matching build products.

Mounting/Using the RootFS
=========================

The RootFS and compiler shards, as they are referred to, are hosted on Amazon S3 buckets and available in both `.tar.gz` archives as well as `.squashfs` files.  When downloaded, they should be extracted/mounted in a configuration similar to the following:

* `RootFS` shard mounted at `/` (contains Alpine base image, general native tools such as `bash`, `cmake`, etc....)
* `BaseCompilerShard` mounted at `/opt/${target}` (contains kernel headers, target libc, CMake toolchain definitions, etc...)
* `binutils` shard mounted at `/opt/${target}/binutils-${binutils_version}` (contains `ld`, `as`, etc...)
* `GCC` shard mounted at `/opt/${target}/gcc-${gcc_version}` (contains `gcc`,  `g++`, `gfortran`, etc...)
* `clang` shard mounted at `/opt/x86_64-linux-gnu/clang-${clang_version}` (contains `clang`, `clang++`, etc...)

Upon launch, the rootfs system should "coalesce" all files within `/opt/${target}/*` to a single, merged, tree in `/opt/${target}`.  This is done automatically by the `sandbox` isolation utility utilized by the User Namespace runner within `BinaryBuilder.jl`, but for other methods of using this build environment, you should run the following `bash` script at startup:

```bash
function join_by { local IFS="$1"; shift; echo "$*"; }

for f in /opt/*; do
    mount -t overlay overlay -olowerdir=$(join_by ":" "${f}"/*) "${f}"
done
```

This will merge any shard file trees together into a single, unified tree, allowing us to, for example, merge the `binutils`, `GCC`, and `clang` shards into the same `/opt/x86_64-linux-gnu` directory.

The [`BinaryBuilder.jl`](https://github.com/JuliaPackaging/BinaryBuilder.jl) Julia package contains all the logic necessary to download, extract, and run these compiler shares interactively on both Linux and MacOS hosts.  Run the following Julia script to install BinaryBuilder, download the appropriate compiler shard, and launch into an interactive, isolated environment with your current directory mapped into the build environment:

```julia
Pkg.add("BinaryBuilder")
using BinaryBuilder
BinaryBuilder.runshell(Platform("x86_64", "linux"))
```
