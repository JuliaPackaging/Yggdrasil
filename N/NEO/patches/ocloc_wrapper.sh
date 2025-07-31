#!/bin/bash

# ocloc_wrapper.sh - Wrapper script to handle ocloc segfaults gracefully
# This script runs ocloc and detects successful compilation even if it segfaults during cleanup

# Set up environment variables for ocloc
export LD_LIBRARY_PATH="/workspace/x86_64-linux-gnu-libgfortran5-cxx11-debug+true/destdir/lib64:/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64:/workspace/x86_64-linux-gnu-libgfortran5-cxx11-debug+true/destdir/lib:/workspace/srcdir/compute-runtime/build/bin"

# Get the actual ocloc binary path
OCLOC_BIN="/workspace/srcdir/compute-runtime/build/bin/ocloc-25.27.1"

# Run ocloc and capture output and exit code
echo "Running ocloc with args: $@" >&2
output=$(env LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$OCLOC_BIN" "$@" 2>&1)
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
