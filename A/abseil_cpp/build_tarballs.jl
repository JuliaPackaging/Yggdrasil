# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "abseil_cpp"
version = v"20230125.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/abseil/abseil-cpp", "78be63686ba732b25052be15f8d6dee891c05749"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/abseil-cpp

# ABSL_RANDOM_HWAES_*_FLAGS are used to set ABSL_RANDOM_RANDEN_COPTS,
# which is used when compiling absl/random/internal/randen_hwaes.cc

# Output ABSL_RANDOM_RANDEN_COPTS during configure
atomic_patch -p1 ../patches/cmake-copts.patch

# Allow setting "-march=armv8-a+crypto"
find $(dirname $(which $CC)) -type f \
    | xargs grep --files-with-matches 'BinaryBuilder: Cannot force an architecture via -march' \
    | xargs -n1 sed -i -E 's/^if \[\[ (" \$\{ARGS\[@\]\} " == \*"-march="\*) \]\]; then/if [[\n    \1\n    \&\& ! " \${ARGS[@]} " == *"-march=armv8-a+crypto"*\n]]; then/'

# Do not attempt to set ABSL_RANDOM_HWAES_ARM32_FLAGS (Neon) for armv6l
if [[ "$bb_full_target" == armv6l-* ]]; then
    atomic_patch -p1 ../patches/arm-neon-cmake.patch
fi

# For some reason, the ABSL_RANDOM_HWAES_X64_FLAGS are applied for aarch64-apple-darwin,
# and the ABSL_RANDOM_HWAES_ARM64_FLAGS are applied for x86_64-apple-darwin
if [[ "$target" == aarch64-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/x86_64-aes-cmake.patch
elif [[ "$target" == x86_64-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/aarch64-crypto-cmake.patch
fi

cmake -B build -G Ninja \
    -DABSL_PROPAGATE_CXX_STD=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libabsl_bad_any_cast_impl", :libabsl_bad_any_cast_impl),
    LibraryProduct("libabsl_bad_optional_access", :libabsl_bad_optional_access),
    LibraryProduct("libabsl_bad_variant_access", :libabsl_bad_variant_access),
    LibraryProduct("libabsl_base", :libabsl_base),
    LibraryProduct("libabsl_city", :libabsl_city),
    LibraryProduct("libabsl_civil_time", :libabsl_civil_time),
    LibraryProduct("libabsl_cord", :libabsl_cord),
    LibraryProduct("libabsl_cord_internal", :libabsl_cord_internal),
    LibraryProduct("libabsl_cordz_functions", :libabsl_cordz_functions),
    LibraryProduct("libabsl_cordz_handle", :libabsl_cordz_handle),
    LibraryProduct("libabsl_cordz_info", :libabsl_cordz_info),
    LibraryProduct("libabsl_cordz_sample_token", :libabsl_cordz_sample_token),
    LibraryProduct("libabsl_crc32c", :libabsl_crc32c),
    LibraryProduct("libabsl_crc_cord_state", :libabsl_crc_cord_state),
    LibraryProduct("libabsl_crc_cpu_detect", :libabsl_crc_cpu_detect),
    LibraryProduct("libabsl_crc_internal", :libabsl_crc_internal),
    LibraryProduct("libabsl_debugging_internal", :libabsl_debugging_internal),
    LibraryProduct("libabsl_demangle_internal", :libabsl_demangle_internal),
    LibraryProduct("libabsl_die_if_null", :libabsl_die_if_null),
    LibraryProduct("libabsl_examine_stack", :libabsl_examine_stack),
    LibraryProduct("libabsl_exponential_biased", :libabsl_exponential_biased),
    LibraryProduct("libabsl_failure_signal_handler", :libabsl_failure_signal_handler),
    LibraryProduct("libabsl_flags", :libabsl_flags),
    LibraryProduct("libabsl_flags_commandlineflag", :libabsl_flags_commandlineflag),
    LibraryProduct("libabsl_flags_commandlineflag_internal", :libabsl_flags_commandlineflag_internal),
    LibraryProduct("libabsl_flags_config", :libabsl_flags_config),
    LibraryProduct("libabsl_flags_internal", :libabsl_flags_internal),
    LibraryProduct("libabsl_flags_marshalling", :libabsl_flags_marshalling),
    LibraryProduct("libabsl_flags_parse", :libabsl_flags_parse),
    LibraryProduct("libabsl_flags_private_handle_accessor", :libabsl_flags_private_handle_accessor),
    LibraryProduct("libabsl_flags_program_name", :libabsl_flags_program_name),
    LibraryProduct("libabsl_flags_reflection", :libabsl_flags_reflection),
    LibraryProduct("libabsl_flags_usage", :libabsl_flags_usage),
    LibraryProduct("libabsl_flags_usage_internal", :libabsl_flags_usage_internal),
    LibraryProduct("libabsl_graphcycles_internal", :libabsl_graphcycles_internal),
    LibraryProduct("libabsl_hash", :libabsl_hash),
    LibraryProduct("libabsl_hashtablez_sampler", :libabsl_hashtablez_sampler),
    LibraryProduct("libabsl_int128", :libabsl_int128),
    LibraryProduct("libabsl_leak_check", :libabsl_leak_check),
    LibraryProduct("libabsl_log_entry", :libabsl_log_entry),
    LibraryProduct("libabsl_log_flags", :libabsl_log_flags),
    LibraryProduct("libabsl_log_globals", :libabsl_log_globals),
    LibraryProduct("libabsl_log_initialize", :libabsl_log_initialize),
    LibraryProduct("libabsl_log_internal_check_op", :libabsl_log_internal_check_op),
    LibraryProduct("libabsl_log_internal_conditions", :libabsl_log_internal_conditions),
    LibraryProduct("libabsl_log_internal_format", :libabsl_log_internal_format),
    LibraryProduct("libabsl_log_internal_globals", :libabsl_log_internal_globals),
    LibraryProduct("libabsl_log_internal_log_sink_set", :libabsl_log_internal_log_sink_set),
    LibraryProduct("libabsl_log_internal_message", :libabsl_log_internal_message),
    LibraryProduct("libabsl_log_internal_nullguard", :libabsl_log_internal_nullguard),
    LibraryProduct("libabsl_log_internal_proto", :libabsl_log_internal_proto),
    LibraryProduct("libabsl_log_severity", :libabsl_log_severity),
    LibraryProduct("libabsl_log_sink", :libabsl_log_sink),
    LibraryProduct("libabsl_low_level_hash", :libabsl_low_level_hash),
    LibraryProduct("libabsl_malloc_internal", :libabsl_malloc_internal),
    LibraryProduct("libabsl_periodic_sampler", :libabsl_periodic_sampler),
    LibraryProduct("libabsl_random_distributions", :libabsl_random_distributions),
    LibraryProduct("libabsl_random_internal_distribution_test_util", :libabsl_random_internal_distribution_test_util),
    LibraryProduct("libabsl_random_internal_platform", :libabsl_random_internal_platform),
    LibraryProduct("libabsl_random_internal_pool_urbg", :libabsl_random_internal_pool_urbg),
    LibraryProduct("libabsl_random_internal_randen", :libabsl_random_internal_randen),
    LibraryProduct("libabsl_random_internal_randen_hwaes", :libabsl_random_internal_randen_hwaes),
    LibraryProduct("libabsl_random_internal_randen_hwaes_impl", :libabsl_random_internal_randen_hwaes_impl),
    LibraryProduct("libabsl_random_internal_randen_slow", :libabsl_random_internal_randen_slow),
    LibraryProduct("libabsl_random_internal_seed_material", :libabsl_random_internal_seed_material),
    LibraryProduct("libabsl_random_seed_gen_exception", :libabsl_random_seed_gen_exception),
    LibraryProduct("libabsl_random_seed_sequences", :libabsl_random_seed_sequences),
    LibraryProduct("libabsl_raw_hash_set", :libabsl_raw_hash_set),
    LibraryProduct("libabsl_raw_logging_internal", :libabsl_raw_logging_internal),
    LibraryProduct("libabsl_scoped_set_env", :libabsl_scoped_set_env),
    LibraryProduct("libabsl_spinlock_wait", :libabsl_spinlock_wait),
    LibraryProduct("libabsl_stacktrace", :libabsl_stacktrace),
    LibraryProduct("libabsl_status", :libabsl_status),
    LibraryProduct("libabsl_statusor", :libabsl_statusor),
    LibraryProduct("libabsl_str_format_internal", :libabsl_str_format_internal),
    LibraryProduct("libabsl_strerror", :libabsl_strerror),
    LibraryProduct("libabsl_strings", :libabsl_strings),
    LibraryProduct("libabsl_strings_internal", :libabsl_strings_internal),
    LibraryProduct("libabsl_symbolize", :libabsl_symbolize),
    LibraryProduct("libabsl_synchronization", :libabsl_synchronization),
    LibraryProduct("libabsl_throw_delegate", :libabsl_throw_delegate),
    LibraryProduct("libabsl_time", :libabsl_time),
    LibraryProduct("libabsl_time_zone", :libabsl_time_zone),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"7",
)
