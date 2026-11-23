# Licences of LibGit2_wasm

`wasm32-wasip1/lib/libgit2.a` is libgit2 1.9.7 with the patches in `share/src/LibGit2_wasm/patches`.
`wasm32-wasip1/lib/libgit2.wasm` is that library, a wrapper (`lg2w.c`) and wasi-libc linked into one
WebAssembly module.

| Part | Licence | File |
|---|---|---|
| libgit2, and the patches to it | GPL-2.0-only WITH the libgit2 linking exception | `COPYING` (first part) |
| xdiff (`deps/xdiff`, in libgit2) | LGPL-2.1-or-later | `COPYING` (the LGPL text at its end) |
| PCRE2 (`deps/pcre2`, libgit2's regex backend) | BSD-3-Clause WITH PCRE2-exception | `pcre2-LICENCE.md` |
| zlib (`deps/zlib`) | Zlib | `zlib-LICENSE` |
| llhttp (`deps/llhttp`) | MIT | `llhttp-LICENSE-MIT` |
| SHA-1 collision detection (`src/util/hash/sha1dc`) | MIT | `sha1dc-LICENSE.txt` |
| wasi-libc (wasi-sdk 34), in `libgit2.wasm` | Apache-2.0 WITH LLVM-exception, MIT and others | `wasi-libc/` |
| `lg2w.c` | MIT | the header of `share/src/LibGit2_wasm/lg2w.c` |

The linking exception lets a program link libgit2 and distribute the combination without the GPL's
conditions applying to the program. Distributing libgit2 on its own, as here, is under the GPL:
the corresponding source is in `share/src/LibGit2_wasm/` (libgit2's release tarball by URL and
hash, the patches, the wrapper and the build scripts). The module is a separate WebAssembly
instance that a program imports, so it can be replaced by any other build of the same source,
which is what LGPL-2.1 asks for xdiff.
