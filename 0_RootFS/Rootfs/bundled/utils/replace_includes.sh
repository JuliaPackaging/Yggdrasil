#!/bin/sh
# -r = recursive
# -l = files-with-matches
# -i = in-place
grep -r -l "#\s*include\s*<$1.h>" . | xargs sed -i "s/#\s*include\s*<$1.h>/#include <$2.h>/"
