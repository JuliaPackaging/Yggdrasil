#!/bin/sh

# If the input doesn't exist, throw an error.
if test ! -e "${1}"; then
    echo "ldd: ${1}:" "No such file or directory" >&2
    exit 1
fi

# Paths to various programs we need
PATCHELF=/usr/local/bin/patchelf
MUSL_LD=/lib/ld-musl-x86_64.so.1
#GLIBC_LD=/usr/glibc-compat/lib/ld-linux-x86-64.so.2
GLIBC_LD=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib64/ld-linux-x86-64.so.2


# If the given ELF file has an interpreter baked into it, then
# tell it to be `ldd` and invoke it directly.
if interp=$(${PATCHELF} --print-interpreter "${1}" 2>/dev/null); then
    LD_TRACE_LOADED_OBJECTS=1 exec -a ldd "${interp}" "$@"
fi

# Otherwise, check out the needed section to see if we can auto-detect
# a musl binary (as opposed to a glibc binary)
needed=$(${PATCHELF} --print-needed "${1}" 2>/dev/null)

if test "${needed#*libc.musl-x86_64.so.1}" != "$needed"; then
    # Tell the musl loader to act like `ldd` and sub off to it
    exec -a ldd "${MUSL_LOADER}" "$@"
else
    # Otherwise, tell the glibc loader to act like `ldd` and sub off to that
    LD_TRACE_LOADED_OBJECTS=1 exec -a ldd "${GLIBC_LD}" $@
fi

