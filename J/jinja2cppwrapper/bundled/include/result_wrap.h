#ifndef RESULT_WRAP_H
#define RESULT_WRAP_H

#ifdef __cplusplus
#include "jinja2cpp/template.h"
#include <nonstd/expected.hpp>
#include "error_info_wrap.h"
#include <stdbool.h>
#include <stddef.h>

using jinja2cpp_template_t = jinja2::Template;
template <typename T>
using jinja2cpp_result_t = nonstd::expected<T, jinja2cpp_error_info_t>;

extern "C" {
#endif

void jinja2cpp_result_free_void(jinja2cpp_result_t<void*>* result);
void jinja2cpp_result_free_string(jinja2cpp_result_t<const char*>* result);
void jinja2cpp_result_free_template(jinja2cpp_result_t<jinja2cpp_template_t*>* result);

bool jinja2cpp_result_has_value_void(const jinja2cpp_result_t<void*>* result);
bool jinja2cpp_result_has_value_string(const jinja2cpp_result_t<const char*>* result);
bool jinja2cpp_result_has_value_template(const jinja2cpp_result_t<jinja2cpp_template_t*>* result);

const void* jinja2cpp_result_value_void(const jinja2cpp_result_t<void*>* result);
const char* jinja2cpp_result_value_string(const jinja2cpp_result_t<const char*>* result);
jinja2cpp_template_t* jinja2cpp_result_value_template(const jinja2cpp_result_t<jinja2cpp_template_t*>* result);

const jinja2cpp_error_info_t* jinja2cpp_result_error_void(const jinja2cpp_result_t<void*>* result);
const jinja2cpp_error_info_t* jinja2cpp_result_error_string(const jinja2cpp_result_t<const char*>* result);
const jinja2cpp_error_info_t* jinja2cpp_result_error_template(const jinja2cpp_result_t<jinja2cpp_template_t*>* result);

#ifdef __cplusplus
}
#endif

#endif // RESULT_WRAP_H