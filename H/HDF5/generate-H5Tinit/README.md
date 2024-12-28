# Generating H5Tinit.c

The HDF5 library compiles and runs at build time, a file `H5detect.c`
which generates another file `H5Tinit.c` that is compiled as part of
the HDF5 library. This file contains ABI definitions of the supported
floating point types, usually `float`, `double`, and `long double`.

Since BinaryBuilder cross-compiles, we cannot run `H5detect`, and we
thus collect the generated files `H5Tinit.c` ahead of time. This is
safe because the floating point ABI is a very basic feature of the
system ABI and will not change. The floating-point ABI depends on the
hardware (CPU) and conventions set by the operating system.

In practice there are only three different operating system
conventions: Apple, Unix, and Windows.

In practice, there are only two possible ABIs `float` and `double`,
namely a little-endian and a big-endian memory layout. For `long
double` there are a more choices: `long double` can either be
identical to `double`, can have 80 bits, or can have a full 128 bits.
When it has 80 bits, then its memory layout could additionally be
padded to 12 or 16 bytes.

The scripts in this directory use Docker to generate these `H5Tinit.c`
files for various Linux architectures. For Apple (`darwin`) and
Windows these files were either generated or written manually.
