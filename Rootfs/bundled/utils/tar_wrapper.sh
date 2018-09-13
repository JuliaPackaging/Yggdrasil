#!/bin/sh

# Forcibly insert --no-same-owner into every tar invocation,
# since we run in a single-user environment.
/usr/bin/tar $* --no-same-owner
