#!/bin/sh

# We need a special `sha512sum` compat shim to work around
# GCC and other build systems that don't know how to deal
# with busybox.

if [ "$1" = "--check" ]; then
    shift
    exec /bin/busybox sha512sum -c "$@"
fi
exec /bin/busybox sha512sum "$@"
