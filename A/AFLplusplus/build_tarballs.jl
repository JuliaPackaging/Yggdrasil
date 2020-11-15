using BinaryBuilder, Pkg.Types

name = "AFLplusplus"
version = v"2.68"
sources = [
    ArchiveSource("https://github.com/AFLplusplus/AFLplusplus/archive/2.68c.tar.gz", "862e155c97737770baa26ffedf324a7fa255b757c85b0c9a6f312264f2ca29c5"),
    ArchiveSource("http://download.qemu-project.org/qemu-3.1.0.tar.xz", "6a0508df079a0a33c2487ca936a56c12122f105b8a96a44374704bef6c69abfc", unpack_target="AFLplusplus-2.68c/qemu_mode"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/AFLplusplus-2.68c

# Patch the makefile to not use llvm-config. The llvm-config binary from Clang_jll cannot be used when cross compiling
atomic_patch -p1 ${WORKSPACE}/srcdir/llvm_mode_makefile.patch

export REAL_CC="clang"
export REAL_CXX="clang++"
export AFL_CC="$prefix/tools/clang"
export AFL_CXX="$prefix/tools/clang++"
export AFL_PATH="$libdir/afl"
export PREFIX=$prefix

cd llvm_mode
make
make install

install_license ${WORKSPACE}/srcdir/AFLplusplus-2.68c/LICENSE

# QEMU mode is only working on Linux glibc platforms
if [[ "${target}" != *-freebsd* ]] && [[ "${target}" != *-apple-* ]] && [[ "${target}" != *-*-musl ]]; then
    cd ../qemu_mode/qemu-3.1.0/

	# apply patches from AFL's qemu_mode
	atomic_patch -p1 ../patches/elfload.diff
	atomic_patch -p1 ../patches/mips-fpu.diff
	atomic_patch -p1 ../patches/bsd-elfload.diff
	atomic_patch -p1 ../patches/cpu-exec.diff
	atomic_patch -p1 ../patches/syscall.diff
	atomic_patch -p1 ../patches/translate-all.diff
	atomic_patch -p1 ../patches/tcg.diff
	atomic_patch -p1 ../patches/i386-translate.diff
	atomic_patch -p1 ../patches/arm-translate.diff
	atomic_patch -p1 ../patches/arm-translate-a64.diff
	atomic_patch -p1 ../patches/i386-ops_sse.diff
	atomic_patch -p1 ../patches/i386-fpu_helper.diff
	atomic_patch -p1 ../patches/softfloat.diff
	atomic_patch -p1 ../patches/configure.diff
	atomic_patch -p1 ../patches/tcg-runtime.diff
	atomic_patch -p1 ../patches/tcg-runtime-head.diff
	atomic_patch -p1 ../patches/translator.diff
	atomic_patch -p1 ../patches/__init__.py.diff
	atomic_patch -p1 ../patches/make_strncpy_safe.diff
	atomic_patch -p1 ../patches/mmap_fixes.diff

	./configure --disable-system \
		--enable-linux-user --disable-gtk --disable-sdl --disable-vnc --enable-capstone=internal \
		--target-list="i386-linux-user,x86_64-linux-user,arm-linux-user,aarch64-linux-user,ppc-linux-user" --enable-pie --python="/usr/bin/python3"

	make -j${nproc}

	install i386-linux-user/qemu-i386 $bindir/afl-qemu-trace-i386
	install x86_64-linux-user/qemu-x86_64 $bindir/afl-qemu-trace-x86_64
	install arm-linux-user/qemu-arm $bindir/afl-qemu-trace-arm
	install aarch64-linux-user/qemu-aarch64 $bindir/afl-qemu-trace-aarch64
	install ppc-linux-user/qemu-ppc $bindir/afl-qemu-trace-ppc
fi
"""

# Windows is not supported by AFL, ARMv7l musl won't build
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("afl-clang-fast", :afl_clang_fast),
    ExecutableProduct("afl-clang-fast++", :afl_clang_fast_cxx),
]

dependencies = [
	Dependency(PackageSpec(name="Clang_jll", version=v"9.0.1")),
	Dependency("Glib_jll"),
	Dependency("Pixman_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
