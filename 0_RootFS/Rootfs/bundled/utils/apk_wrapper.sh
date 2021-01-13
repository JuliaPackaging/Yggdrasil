#!/bin/bash

# We run in a single-user environment, we can't afford running `chown` when
# installing packages.
/sbin/apk --no-chown "$@"
