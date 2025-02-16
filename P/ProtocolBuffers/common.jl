# Protobuf version numbers are weird: The version number across all languages
# only includes the minor and patch release.
# Each language runtime, e.g. the C++ runtime  `libprotobuf`, has its own major
# version on top of that.
# Thus, e.g. ProtocolBuffers, and protoc, v"28.2" matches C++ runtime v"5.28.2".
# 
# Cf. https://github.com/protocolbuffers/protobuf/blob/v28.2/version.json
base_version = v"0.28.2"

sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "9fff46d7327c699ef970769d5c9fd0e44df08fc7"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd $WORKSPACE/srcdir/protobuf

# Avoid problems with `-march`, `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

cmake_extra_args=()
if [[ "$BB_PROTOBUF_BUILD_SHARED_LIBS" == "OFF" ]]; then
    cmake_extra_args+=(
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    )
fi
if [[ "$BB_PROTOBUF_PRODUCT" == "libprotobuf" ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF
    )
elif [[ "$BB_PROTOBUF_PRODUCT" == "protoc" ]]; then
    cmake_extra_args+=(
        -Dprotobuf_BUILD_PROTOBUF_BINARIES=ON
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
    )
else
    exit 1
fi

git submodule update --init --recursive --depth 1
cmake \
    -B build \
    -G Ninja \
    -DBUILD_SHARED_LIBS=$BB_PROTOBUF_BUILD_SHARED_LIBS \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -Dprotobuf_BUILD_TESTS=OFF \
    "${cmake_extra_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

additional_library_symbols = [
    # `protobuf` builds and installs a copy of `abseil_cpp`
    :libabsl_bad_any_cast_impl,
    :libabsl_bad_optional_access,
    :libabsl_bad_variant_access,
    :libabsl_base,
    :libabsl_city,
    :libabsl_civil_time,
    :libabsl_cord,
    :libabsl_cord_internal,
    :libabsl_cordz_functions,
    :libabsl_cordz_handle,
    :libabsl_cordz_info,
    :libabsl_cordz_sample_token,
    :libabsl_crc32c,
    :libabsl_crc_cord_state,
    :libabsl_crc_cpu_detect,
    :libabsl_crc_internal,
    :libabsl_debugging_internal,
    :libabsl_demangle_internal,
    :libabsl_die_if_null,
    :libabsl_examine_stack,
    :libabsl_exponential_biased,
    :libabsl_failure_signal_handler,
    :libabsl_flags_commandlineflag,
    :libabsl_flags_commandlineflag_internal,
    :libabsl_flags_config,
    :libabsl_flags_internal,
    :libabsl_flags_marshalling,
    :libabsl_flags_parse,
    :libabsl_flags_private_handle_accessor,
    :libabsl_flags_program_name,
    :libabsl_flags_reflection,
    :libabsl_flags_usage,
    :libabsl_flags_usage_internal,
    :libabsl_graphcycles_internal,
    :libabsl_hash,
    :libabsl_hashtablez_sampler,
    :libabsl_int128,
    :libabsl_kernel_timeout_internal,
    :libabsl_leak_check,
    :libabsl_log_entry,
    :libabsl_log_flags,
    :libabsl_log_globals,
    :libabsl_log_initialize,
    :libabsl_log_internal_check_op,
    :libabsl_log_internal_conditions,
    :libabsl_log_internal_fnmatch,
    :libabsl_log_internal_format,
    :libabsl_log_internal_globals,
    :libabsl_log_internal_log_sink_set,
    :libabsl_log_internal_message,
    :libabsl_log_internal_nullguard,
    :libabsl_log_internal_proto,
    :libabsl_log_severity,
    :libabsl_log_sink,
    :libabsl_low_level_hash,
    :libabsl_malloc_internal,
    :libabsl_periodic_sampler,
    :libabsl_random_distributions,
    :libabsl_random_internal_distribution_test_util,
    :libabsl_random_internal_platform,
    :libabsl_random_internal_pool_urbg,
    :libabsl_random_internal_randen,
    :libabsl_random_internal_randen_hwaes,
    :libabsl_random_internal_randen_hwaes_impl,
    :libabsl_random_internal_randen_slow,
    :libabsl_random_internal_seed_material,
    :libabsl_random_seed_gen_exception,
    :libabsl_random_seed_sequences,
    :libabsl_raw_hash_set,
    :libabsl_raw_logging_internal,
    :libabsl_scoped_set_env,
    :libabsl_spinlock_wait,
    :libabsl_stacktrace,
    :libabsl_status,
    :libabsl_statusor,
    :libabsl_str_format_internal,
    :libabsl_strerror,
    :libabsl_string_view,
    :libabsl_strings,
    :libabsl_strings_internal,
    :libabsl_symbolize,
    :libabsl_synchronization,
    :libabsl_throw_delegate,
    :libabsl_time,
    :libabsl_time_zone,
    :libabsl_vlog_config_internal,

    # `protobuf` builds and installs some UTF8 libraries
    :libutf8_range,
    :libutf8_validity,
]

dependencies = Dependency[
]
