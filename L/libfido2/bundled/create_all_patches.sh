#!/bin/bash

# Top-level CMake patch
diff -u CMakeLists.txt.orig CMakeLists.txt > patches/toplevel.patch

# src/ (nottoplevel here) CMake patch
diff -u nottoplevel/CMakeLists.txt.orig nottoplevel/CMakeLists.txt > patches/src.patch

# fallthrough patch
diff -u fallthrough.h.orig fallthrough.h > patches/fallthrough.patch

# hid_linux.c patch
diff -u hid_linux.c.orig hid_linux.c > patches/hid_linux.patch

for f in patches/*.patch; do
  sed -i \
    -e 's#^\(---\|+++\) \([a-zA-Z0-9_\.-]*/\)\([A-Za-z0-9_.-]*\)\.orig\([[:space:]]\)#\1 \3\4#' \
    -e 's#^\(---\|+++\) \([a-zA-Z0-9_\.-]*/\)\([A-Za-z0-9_.-]*\)\([[:space:]]\)#\1 \3\4#' \
    -e 's#^\(---\|+++\) \([A-Za-z0-9_.-]*\)\.orig\([[:space:]]\)#\1 \2\3#' \
  "$f"
done
echo "All patches created in ./patches/"

