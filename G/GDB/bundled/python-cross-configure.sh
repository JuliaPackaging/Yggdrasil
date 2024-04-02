#!/bin/sh -ue
#
# script that spoofs the python configuration parameters that GDB would normally get from
# running `python gdb/python/python-config.py`. The values are taken from actually running
# this script in a container where host == target:
# $ PYTHONHOME=$prefix $prefix/bin/python3 gdb/python/python-config.py

python=$1
flag=$2

if [[ $flag == "--prefix" ]]; then
    echo "$prefix"
elif [[ $flag == "--exec-prefix" ]]; then
    echo "$prefix"
elif [[ $flag == "--includes" ]]; then
    echo "-I$prefix/include/python3.10"
elif [[ $flag == "--libs" ]]; then
    echo "-lpython3.10 -lpthread -ldl -lpthread -lutil -lrt -lm -lm"
elif [[ $flag == "--cflags" ]]; then
    echo "-I$prefix/include/python3.10 -I$prefix/include/python3.10 -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall"
elif [[ $flag == "--ldflags" ]]; then
    echo "-lpython3.10 -lpthread -ldl -lpthread -lutil -lrt -lm -lm -Xlinker -export-dynamic"
else
    echo "Unknown flag: $flag"
    exit 1
fi
