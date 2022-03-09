#!/bin/bash

if [[ "${1}" == "add" ]]; then
    # We run in a single-user environment, we can't afford running `chown` when
    # installing packages.
    /sbin/apk --no-chown "$@"
else
    /sbin/apk "$@"
fi
