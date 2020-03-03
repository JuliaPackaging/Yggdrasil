#!/bin/bash
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "${ROOTFS}" ]; then
    ROOTFS=$(julia -e "using BinaryBuilder; rootfs = first(filter(cs -> cs.name == \"Rootfs\" && cs.archive_type == :unpacked, BinaryBuilder.all_compiler_shards())); println(BinaryBuilder.mount_path(rootfs, \"\"))")
fi

# Make temporary directories where we'll have our rootfs/sandbox and our output
PREFIX=$(mktemp -d)
OUTDIR=$(mktemp -d)
cleanup()
{
    rm -rf ${PREFIX}
    rm -rf ${OUTDIR}
}
if [[ $* != *--nocleanup* ]]; then
    trap cleanup EXIT
fi

# Copy rootfs into our prefix, then refer to that 
cp -a ${ROOTFS}/* ${PREFIX}/

# Compile new version of `sandbox.c` (for development)
if ! gcc -o "${PREFIX}/sandbox" "${SRCDIR}/sandbox.c"; then
    exit 1
fi

# Run sandbox, instructing it to directly run _another_ sandbox.  A donut... inside another donut...
export SANDBOX_CMD="${PREFIX}/sandbox"

# We want `--verbose` to be the first thing in the arglist, so we can see the sandbox parse its arguments
if [[ $* == *--verbose* ]]; then
    VERBOSE=1
    SANDBOX_CMD="${SANDBOX_CMD} --verbose"
fi

# Add on our rootfs and furthermore mount it as a read-only mapping
# Then, add a second mapping for our output
SANDBOX_CMD="${SANDBOX_CMD} --rootfs ${PREFIX} --map ${PREFIX}:${PREFIX} --workspace ${OUTDIR}:${OUTDIR}"

# In privileged mode, put `sudo` in front, but only for the first layer
SUDO=""
if [[ $* == *--privileged* ]]; then
    SUDO="sudo"
fi

# In verbose mode, start printing out commands at this point
if [[ $* == *--verbose* ]]; then
    set -x
fi

if [[ $* == *--debug* ]]; then
    ${SUDO} ${SANDBOX_CMD} -- /bin/bash -l
else
    # Two pop culture references in a single bash script?!
    MSG="This just sounds like docker, but with extra steps"

    # First, test direct execution
    DIRECT_OUTPUT=$(${SUDO} ${SANDBOX_CMD} -- /bin/bash -c "echo $MSG")
    if [[ "${DIRECT_OUTPUT}" != "${MSG}" ]]; then
        echo "Direct execution did not work!" >&2
        exit 1
    fi
    echo "PASS: direct execution"

    function check_outpath()
    {
        if [[ ! -f "$1" ]]; then
            echo "$1 does not exist!" >&2
            exit 1
        fi

        if [[ $(stat -c '%u:%g' "$1") != "$(id -u):$(id -g)" ]]; then
            echo "$1 Permissions wrong! $(stat -c '%u %g' "$1")" >&2
            exit 1
        fi

        KNOWN_HASH="2343106e3b721f4aa34a96231848bff458da49965a8f605f726bf90f34f282fa"
        if ! echo "${KNOWN_HASH}  ${1}" | shasum -a 256 -c - >/dev/null; then
            echo "$1 failed hash check!" >&2
            cat "$1" >&2
            exit 1
        fi
    }

    # Next, direct workspacing
    OUTPATH="${OUTDIR}/msg_direct.txt"
    ${SUDO} ${SANDBOX_CMD} -- /bin/bash -c "echo $MSG > ${OUTPATH}"
    check_outpath ${OUTPATH}
    echo "PASS: direct workspacing"

    # Next up, nested execution
    NESTED_OUTPUT=$(${SUDO} ${SANDBOX_CMD} -- ${SANDBOX_CMD} -- /bin/bash -c "echo $MSG")
    if [[ "${NESTED_OUTPUT}" != "${MSG}" ]]; then
        echo "Nested execution did not work!" >&2
        exit 1
    fi
    echo "PASS: nested execution"

    # Finally, nested mounting
    OUTPATH="${OUTDIR}/msg_nested.txt"
    ${SUDO} ${SANDBOX_CMD} -- ${SANDBOX_CMD} -- /bin/bash -c "echo $MSG > ${OUTPATH}"
    check_outpath ${OUTPATH}
    echo "PASS: nested workspacing"
fi