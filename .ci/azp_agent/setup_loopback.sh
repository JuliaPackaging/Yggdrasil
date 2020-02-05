#!/bin/bash

NUM_LOOPBACKS=64
echo -n "Creating $NUM_LOOPBACKS loopback devices..."
for idx in $(seq 1 $((NUM_LOOPBACKS - 1))); do
	if [ -e /dev/loop${idx} ]; then
        continue
    fi

	sudo mknod /dev/loop${idx} b 7 ${idx}
	sudo chown --reference=/dev/loop0 /dev/loop${idx}
	sudo chmod --reference=/dev/loop0 /dev/loop${idx}
    echo -n "."
done
echo