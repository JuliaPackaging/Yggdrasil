# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protoc"

# Protobuf version numbers are weird: The official version number
# across all languages only includes the minor and patch release. Each
# language (e.g. C++) has its own major version number on top of that.
# Thus, e.g. the overall release v"28.2" contains the C++ release
# v"5.28.2". It's unclear to me (@eschnett) what this means for the
# `protoc` binary.
#
# Because we got this version numbering scheme wrong we add 100 to the
# C++ version number for our internal version numbers. Thus C++
# release v"5.28.2" is v"105.28.2" in Julia.
#
# When updating to a new release, check the released `CMakeFiles.txt`
# for the variable `protobuf_VERSION_STRING`. This is the proper C++
# version number we need. (Then add 100 as explained above.)
version = v"105.28.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "9fff46d7327c699ef970769d5c9fd0e44df08fc7"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protobuf

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

git submodule update --init --recursive
cmake -B build -G Ninja \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_BUILD_LIBPROTOC=ON \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_WITH_ZLIB=ON
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libprotoc", :libprotoc),
    LibraryProduct("libprotobuf", :libprotobuf),
    LibraryProduct("libprotobuf-lite", :libprotobuf_lite),
    ExecutableProduct("protoc", :protoc),

    # `protoc` builds and installs a copy of `abseil_cpp`
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
    LibraryProduct("libabsl_kernel_timeout_internal", :libabsl_kernel_timeout_internal),
    LibraryProduct("libabsl_leak_check", :libabsl_leak_check),
    LibraryProduct("libabsl_log_entry", :libabsl_log_entry),
    LibraryProduct("libabsl_log_flags", :libabsl_log_flags),
    LibraryProduct("libabsl_log_globals", :libabsl_log_globals),
    LibraryProduct("libabsl_log_initialize", :libabsl_log_initialize),
    LibraryProduct("libabsl_log_internal_check_op", :libabsl_log_internal_check_op),
    LibraryProduct("libabsl_log_internal_conditions", :libabsl_log_internal_conditions),
    LibraryProduct("libabsl_log_internal_fnmatch", :libabsl_log_internal_fnmatch),
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
    LibraryProduct("libabsl_string_view", :libabsl_string_view),
    LibraryProduct("libabsl_strings", :libabsl_strings),
    LibraryProduct("libabsl_strings_internal", :libabsl_strings_internal),
    LibraryProduct("libabsl_symbolize", :libabsl_symbolize),
    LibraryProduct("libabsl_synchronization", :libabsl_synchronization),
    LibraryProduct("libabsl_throw_delegate", :libabsl_throw_delegate),
    LibraryProduct("libabsl_time", :libabsl_time),
    LibraryProduct("libabsl_time_zone", :libabsl_time_zone),
    LibraryProduct("libabsl_vlog_config_internal", :libabsl_vlog_config_internal),

    # `protoc` builds and installs some UTF8 libraries
    LibraryProduct("libutf8_range", :libutf8_range),
    LibraryProduct("libutf8_validity", :libutf8_validity),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")

# Build trigger: 1
