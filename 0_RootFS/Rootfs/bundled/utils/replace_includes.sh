#!/bin/sh
# grep options:
# -r = recursive
# -l = files-with-matches
# -E = use extended regex
#
# sed options:
# -i = in-place
# use `&` as the regex delimiter for `sed` so that it doesn't conflict with anything in $1 or $2
FILES=$(grep -r -l -E "#\s*include\s*<$1>" .)
for f in ${FILES}; do
    echo " --> ${f}"
    sed -i -e "s&#\s*include\s*<$1>&#include <$2>&" "${f}"
done
