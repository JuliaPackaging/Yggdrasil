#include "error_info_wrap.h"
#include <string>

jinja2cpp_error_code_t jinja2cpp_error_info_get_code(const jinja2cpp_error_info_t* error_info) {
    if (!error_info) {
        return JINJA2CPP_ERROR_UNSPECIFIED;
    }
    return static_cast<jinja2cpp_error_code_t>(error_info->GetCode());
}

const char* jinja2cpp_error_info_to_string(const jinja2cpp_error_info_t* error_info) {
    if (!error_info) {
        return "Unknown error";
    }
    thread_local std::string error_message;
    error_message = error_info->ToString();
    return error_message.c_str();
}