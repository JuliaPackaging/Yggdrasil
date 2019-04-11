The Care and Feeding of a Root Filesystem
=========================================

This document details some of the journey we have embarked upon to create a Linux environment that supports cross-compilation for a very wide range of architectures and platforms.  At the moment of writing, we support the following platforms (expressed in compiler triplet format):

* glibc Linux: `i686-linux-gnu`, `x86_64-linux-gnu`, `aarch64-linux-gnu`, `arm-linux-gnueabihf`, `powerpc64le-linux-gnu`
* musl Linux: `i686-linux-musl`, `x86_64-linux-musl`, `aarch64-linux-musl`, `arm-linux-musleabihf`
* MacOS: `x86_64-apple-darwin14`
* FreeBSD: `x86_64-unknown-freebsd11.1`
* Windows: `i686-w64-mingw32`, `x86_64-w64-mingw32`

These target platforms are compiled for by building a suite a cross-compilers (`gcc`, `gfortran`, `clang`, `binutils`, etc...) that run on `x86-64-linux-musl`, but target the specific platform.  Unfortunately, it is not sufficient to simply build these compilers once per target, because of incompatibilities between the generated code and the user's system where this code may eventually be running.

Sources of incompatibility
==========================

There are multiple sources of incompatibility that can prevent binaries from being portable.  Here is the list of all incompatibility sources we explicitly deal with, and how we address them:

* `libc`: As most support libraries, eventually, depend on C, the C support library must contain the necessary symbols to support whatever calls are made against it from the compiled object.  To ensure this, we build against the oldest version of the C runtime as possible within BinaryBuilder.  On most systems, this simply means compiling against an SDK from an old OS release, on Linux this means compiling against old versions of `glibc`/`musl`.
* `libstdc++`: For projects that use C++, we have the same problem as with `glibc`.  The versioning of `stdlibc++`, however, is locked to the version of `g++` used to compile the object code.  This would be a problem, except for the fact that the `g++` team has done an excellent job of never breaking backward-compatibility, and so we simply ship a very recent `libstdc++` alongside Julia, and we never have to worry about this.  (The excellent news is that, due to the good backwards compatibility, we never have to worry about a newer `libstdc++` breaking code on the user's computer).
* `libgfortran`: For projects that use Fortran, we need to worry about the large ABI-breaking changes made in GCC 4, GCC 7 and GCC 8.  These breaking changes led to the SONAME of `libgfortran` changing, meaning that code compiled by `gfortran4` is not runnable on a system that uses `gfortran7` natively.  To deal with this, we simply have no other choice but to compile all Fortran code `N` times, where `N` is the number of `libgfortran` versions we wish to support.
* `cxx11`: The [C++11 String ABI changes](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html) caused C++ code compiled by GCC 5+ to become incompatible with C++ code compiled by GCC 4-, but with compile-time switches available (`-D_GLIBCXX_USE_CXX11_ABI=0`) to enable compatibility again with later compilers, which is turned on by some distro compilers.
* `binutils`: Using too new of a `binutils` can cause static libraries to be unusable by older `ld` versions.  To deal with this, we use a `binutils` version that is appropriate for the GCC version in use.
* `clang`: No incompatibilities known.  <3

Compiler Shards
===============

To deal with the above sources of incompatibility, we compile the following shards:

* `clang` (one shard for all targets)
* `GCC+binutils`, split by version according to the following table:

    |  GCC  | Binutils | libgfortran SONAME | string ABI |
    |-------|----------|--------------------|------------|
    | 4.8.5 |  2.24    | libgfortran.so.3   |  cxx03     |
    | 5.2.0 |  2.25.1  | libgfortran.so.3   |  cxx11     |
    | 6.1.0*|  2.26    | libgfortran.so.3   |  cxx11     |
    | 7.1.0 |  2.27    | libgfortran.so.4   |  cxx11     |
    | 8.1.0 |  2.31    | libgfortran.so.5   |  cxx11     |

Our GCC version selection is informed by two requirements: the `libgfortran` and `cxx11` incompatibilities.  First off, we must select compiler versions that span the three `libgfortran` SONAMEs we support, and we choose the oldest possible compilers within each SONAME bucket, yielding GCC `4.8.5`, `7.1.0` and `8.1.0`.  We choose the oldest possible GCC version so as to maximize the chance that C++ code compiled via this shard will be portable on other user's systems even without Julia's bundled `libstdc++.so`.  Next, we must provide a way for a user that is on a system with cxx11-defaulted strings but still using `libgfortran.so.3` (this would be the case if they were using GCC 5.3.1, for example, as Ubuntu 16.04 does) to link against our C++ code, so we add `5.2.0` in as the oldest 5.X.0 version that compiles on all our platforms, links against `libgfortran.so.3`, and defaults to `cxx11` string ABI.

We also compile `GCC 6.1.0` because we have had a report of at least one piece of software that refuses to build with anything older, but also contains Fortran code, and so we needed something that would work on `libgfortran.so.3` systems.  We include it here as part of the build, but it is somewhat "hidden" from the user, and will never be used to compile automatically, it must be manually selected.
