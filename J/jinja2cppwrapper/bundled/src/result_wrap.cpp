#include "result_wrap.h"

bool jinja2cpp_result_has_value_void(const jinja2cpp_result_t<void*>* result) {
    return result && result->has_value();
}

bool jinja2cpp_result_has_value_string(const jinja2cpp_result_t<const char*>* result) {
    return result && result->has_value();
}

const void* jinja2cpp_result_value_void(const jinja2cpp_result_t<void*>* result) {
    if (!result || !result->has_value()) return nullptr;
    return result->value();
}

const char* jinja2cpp_result_value_string(const jinja2cpp_result_t<const char*>* result) {
    if (!result || !result->has_value()) return nullptr;
    static std::string temp_result;
    temp_result = result->value();
    return temp_result.c_str();
}

const jinja2cpp_error_info_t* jinja2cpp_result_error_void(const jinja2cpp_result_t<void*>* result) {
    if (!result || result->has_value()) return nullptr;
    static jinja2cpp_error_info_t temp_error;
    temp_error = result->error();
    return &temp_error;
}

const jinja2cpp_error_info_t* jinja2cpp_result_error_string(const jinja2cpp_result_t<const char*>* result) {
    if (!result || result->has_value()) return nullptr;
    static jinja2cpp_error_info_t temp_error;
    temp_error = result->error();
    return &temp_error;
}