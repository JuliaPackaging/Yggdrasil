#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <symlink_path>"
    exit 1
fi

function isabspath()
{
    case "$1" in
        /*) return 0;;
        *)  return 1;;
    esac
}

function can_chop_dds()
{
    src="$1"
    dest="$2"

    # If we can't move any higher with `src`, then quit
    if [ $(dirname "${src}") = "${src}" ]; then
        return 1
    fi

    # If `dest` isn't trying to move higher, then quit
    case "$dest" in
        ../*) ;;
        *)    return 1;;
    esac

    # Otherwise, we can lop off a `../` from `dest`, and take the dirname of `src`.
    return 0;
}



# Read symlink, if it's already an absolute path, then quit out now!
path="$1"
link_target="$(readlink "$path")"
if isabspath "${link_target}"; then
    exit 0
fi

# First, chop off leading `../` 
while can_chop_dds "${path}" "${link_target}"; do
    path="$(dirname "${path}")"
    link_target=$"{link_target#???}"
done

target_abs_path=$(realpath "$1/${link_target}")
