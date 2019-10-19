compiler_shard_def()
{
    PROG="$1"
    SHARD_NAME="$2"

    if [[ -z "$(qwhich "$PROG")" ]]; then
        eval "${PROG}() { \
            if [ -z \"\$(qwhich ${PROG})\" ]; then \
                echo \"You tried to run '$PROG' which requires the '$SHARD_NAME' shard; add 'compilers=[:${SHARD_NAME}]' to your invocation!\" >&2; \
                return 1; \
            else \
                unset -f $PROG
                $PROG \"\$@\"; \
            fi; \
        }"
    fi
}

# Catch attempts to run C compilers without the :c shard
compiler_shard_def "gcc" "c"
compiler_shard_def "clang" "c"
compiler_shard_def "cc" "c"

# Can't do the `++` names as that's not a valid sh function. lol.
#compiler_shard_def "g++" "c"
#compiler_shard_def "c++" "c"
#compiler_shard_def "clang++" "c"

# One day, my boy, you will have your own shard!
compiler_shard_def "f77" "c"
compiler_shard_def "gfortran" "c"

# Catch attempts to run Rust compilers without the :rust shard
compiler_shard_def "rustc" "rust"
compiler_shard_def "cargo" "rust"

# Same for Go
compiler_shard_def "go" "go"
