#ifndef RESULT_WRAP_H
#define RESULT_WRAP_H

#ifdef __cplusplus
#include <nonstd/expected.hpp>
#include "error_info_wrap.h"
#include <stdbool.h>
#include <stddef.h>

template <typename T>
using jinja2cpp_result_t = nonstd::expected<T, jinja2cpp_error_info_t>;

extern "C" {
#endif

bool jinja2cpp_result_has_value_void(const jinja2cpp_result_t<void*>* result);
bool jinja2cpp_result_has_value_string(const jinja2cpp_result_t<const char*>* result);

const void* jinja2cpp_result_value_void(const jinja2cpp_result_t<void*>* result);
const char* jinja2cpp_result_value_string(const jinja2cpp_result_t<const char*>* result);

const jinja2cpp_error_info_t* jinja2cpp_result_error_void(const jinja2cpp_result_t<void*>* result);
const jinja2cpp_error_info_t* jinja2cpp_result_error_string(const jinja2cpp_result_t<const char*>* result);

#ifdef __cplusplus
}
#endif

#endif // RESULT_WRAP_H