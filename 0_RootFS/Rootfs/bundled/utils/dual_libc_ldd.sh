#!/bin/sh

# If the input doesn't exist, throw an error.
if test ! -e "${1}"; then
    echo "ldd: ${1}:" "No such file or directory" >&2
    exit 1
fi

# Paths to various programs we need
PATCHELF=/usr/bin/patchelf
MUSL_LD=/lib/ld-musl-x86_64.so.1
GLIBC64_LD=/lib64/ld-linux-x86-64.so.2
GLIBC32_LD=/lib/ld-linux.so.2


# If the given ELF file has an interpreter baked into it, then
# tell it to be `ldd` and invoke it directly.
if interp=$(${PATCHELF} --print-interpreter "${1}" 2>/dev/null); then
    LD_TRACE_LOADED_OBJECTS=1 exec -a ldd "${interp}" "$@"
fi

# Otherwise, check out the needed section to see if we can auto-detect
# a musl, glibc32 or glibc64 binary
needed=$(${PATCHELF} --print-needed "${1}" 2>/dev/null)

case $needed in
    *libc.musl-x86_64.so.1*)
        # Tell the musl loader to act like `ldd` and sub off to it
        exec -a ldd "${MUSL_LD}" "$@"
        ;;
    *ld-linux.so.2*)
        # Tell the glibc32 loader to act like `ldd` and sub off to it
        LD_TRACE_LOADED_OBJECTS=1 exec -a ldd "${GLIBC32_LD}" "$@"
        ;;
    *)
        # By default, we just shove everything off to the glibc64 loader
        LD_TRACE_LOADED_OBJECTS=1 exec -a ldd "${GLIBC64_LD}" "$@"
        ;;
esac

