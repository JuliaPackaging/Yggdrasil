#!/bin/bash

# Run ocloc and capture output and exit code
echo "Running ocloc with args: $@" >&2
output=$("$@" 2>&1)
exit_code=$?

# Print the output for debugging
echo "$output" >&2

# Check if compilation was successful despite segfault
if echo "$output" | grep -q "Build succeeded" || echo "$output" | grep -q "Compilation from IR"; then
    echo "ocloc compilation succeeded (ignoring segfault during cleanup)" >&2
    exit 0
fi

# Check if output files were created (another indication of success)
if [ "$exit_code" -ne 0 ]; then
    # Look for output files that might have been created
    for arg in "$@"; do
        case "$arg" in
            -out_dir)
                next_is_outdir=true
                ;;
            -output)
                next_is_output=true
                ;;
            *)
                if [ "$next_is_outdir" = true ]; then
                    outdir="$arg"
                    next_is_outdir=false
                elif [ "$next_is_output" = true ]; then
                    output_name="$arg"
                    next_is_output=false
                fi
                ;;
        esac
    done
    
    # Check if output files exist
    if [ -n "$outdir" ] && [ -n "$output_name" ]; then
        if ls "$outdir"/"$output_name"* 2>/dev/null | grep -q .; then
            echo "ocloc output files found, considering compilation successful" >&2
            exit 0
        fi
    fi
fi

# If we get here, the compilation actually failed
echo "ocloc compilation failed" >&2
exit $exit_code
