using BinaryBuilder

name = "AFL"
version = v"2.68"
sources = [
    ArchiveSource("https://github.com/AFLplusplus/AFLplusplus/archive/2.68c.tar.gz", "862e155c97737770baa26ffedf324a7fa255b757c85b0c9a6f312264f2ca29c5"),
    # AFL expects qemu sources in a specific directory
    ArchiveSource("http://download.qemu-project.org/qemu-3.1.0.tar.xz", "6a0508df079a0a33c2487ca936a56c12122f105b8a96a44374704bef6c69abfc", unpack_target="AFLplusplus-2.68c/qemu_mode"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/AFLplusplus-2.68c

make PROGS="afl-gcc" -j${nproc}
make PREFIX=$prefix PROGS="afl-gcc" SH_PROGS= install

# afl-gcc can only compile instrumention code into x86[_64] programs, just build a stub on other platforms
if [[ ${proc_family} = "intel" ]]; then
	AFL_PATH=$prefix/lib/afl $prefix/bin/afl-gcc test-instr.c -o $prefix/bin/afl-test-instr
else
	$CC test-instr.c -o $prefix/bin/afl-test-instr
fi

# next is compilation of qemu_mode

cd qemu_mode/qemu-3.1.0/

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

install i386-linux-user/qemu-i386 $prefix/bin/afl-qemu-trace-i386
install x86_64-linux-user/qemu-x86_64 $prefix/bin/afl-qemu-trace-x86_64
install arm-linux-user/qemu-arm $prefix/bin/afl-qemu-trace-arm
install aarch64-linux-user/qemu-aarch64 $prefix/bin/afl-qemu-trace-aarch64
install ppc-linux-user/qemu-ppc $prefix/bin/afl-qemu-trace-ppc
"""

# AFL does not support Windows
# QEMU 3.1.0 fails to build with musl
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("afl-gcc", :afl_gcc_exe),
    ExecutableProduct("afl-test-instr", :afl_test_instr_exe),
    ExecutableProduct("afl-qemu-trace-i386", :afl_qemu_trace_i386_exe),
    ExecutableProduct("afl-qemu-trace-x86_64", :afl_qemu_trace_x86_64_exe),
    ExecutableProduct("afl-qemu-trace-arm", :afl_qemu_trace_arm_exe),
    ExecutableProduct("afl-qemu-trace-aarch64", :afl_qemu_trace_aarch64_exe),
]

dependencies = [
	Dependency("Glib_jll"),
	Dependency("Pixman_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
