#!/bin/bash

# We build a uname that pretends to be a different kind of system.
# This is a last-ditch attempt to get simplistic build systems to
# deal with things transparently, when they don't use autoconf or
# a similar system that understands how to cross-compile.  This
# script queues off of the `$target` environment variable.

if [[ -z "${target}" ]]; then
    # Fast path if target environment variable is empty
    /bin/uname "$@"
    exit 0
fi

# ${target} overrides the -s part of uname
s_flag()
{
    case "${target}" in
        *-linux*)
            echo "Linux" ;;
        *-darwin*)
            echo "Darwin" ;;
        *-mingw*)
            echo "MSYS_NT-6.3" ;;
        *-freebsd*)
            echo "FreeBSD" ;;
        *)
            /bin/uname -s ;;
    esac
}

# Kernel version.  Mimic Cygwin/Darwin when appropriate
r_flag()
{
    case "${target}" in
        *-darwin*)
            echo "14.5.0" ;;
        *-mingw*)
            echo "2.8.2(0.313/5/3)" ;;
        *-freebsd*)
            echo "11.1-RELEASE-p9" ;;
        *)
            # On Linux platforms, actually report the real kernel release.
            /bin/uname -r ;;
    esac
}

v_flag()
{
    # Easter egg
    julia_tag_time=$(date -u -d 2013.02.13-00:49:00)
    case "${target}" in
        *-darwin*)
            echo "Darwin Kernel Version $(r_flag): ${julia_tag_time}; root:xnu-9000/RELEASE_X86_64" ;;
        *-linux*)
            echo "#1 JuliaOS SMP PREEMPT ${julia_tag_time}" ;;
        *-mingw*)
            echo "${julia_tag_time}" ;;
        *-freebsd*)
            echo "FreeBSD $(r_flag) #0: ${julia_tag_time} root@build.julialang.org:/julia" ;;
        *)
            /bin/uname -v ;;
    esac
}

m_flag()
{
    case "${target}" in
        arm*)
            echo "armv7l" ;;
        powerpc64le*)
            echo "ppc64le" ;;
        x86_64*)
            case "${target}" in
                *-freebsd*)
                    # FreeBSD calls x86_64 amd64 instead.
                    echo "amd64" ;;
                *)
                    echo "x86_64" ;;
            esac ;;
        i686*)
            echo "i686" ;;
        aarch64*)
            echo "aarch64" ;;
        *)
            # If we don't know, just pass through the native machine type.
            /bin/uname -m ;;
    esac
}

o_flag()
{
    case "${target}" in
        # Darwin doesn't have an -o flag!
        *-darwin*)
            echo "" ;;
        *-linux*)
            echo "GNU/Linux" ;;
        *-mingw*)
            echo "Cygwin" ;;
        *)
            /bin/uname -o ;;
    esac
}

# uname -a is not exactly the same across all platforms; we're mimicking Arch Linux here.
a_flag()
{
    echo $(s_flag) $(/bin/uname -n) $(r_flag) $(v_flag) $(m_flag) $(o_flag)
}



if [[ -z "$@" ]]; then
    s_flag
else
    for flag in $@; do
        case "${flag}" in
            -a)
                a_flag ;;
            -s)
                s_flag ;;
            -r)
                r_flag ;;
            -v)
                v_flag ;;
            -m)
                m_flag ;;
            -p)
                m_flag ;;
            -i)
                m_flag ;;
            -o)
                o_flag ;;
            *)
                /bin/uname ${flag} ;;
        esac
    done
fi

