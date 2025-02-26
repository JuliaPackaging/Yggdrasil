#include "template_wrap.h"
#include <cstring>

jinja2cpp_template_t* jinja2cpp_template_create() {
    return new jinja2cpp_template_t();
}

jinja2cpp_template_t* jinja2cpp_template_create_template_env(jinja2cpp_template_env_t* env) {
    return new jinja2cpp_template_t(env);
}

void jinja2cpp_template_destroy(jinja2cpp_template_t* tpl) {
    delete tpl;
}

jinja2cpp_result_t<void>* jinja2cpp_load(jinja2cpp_template_t* tpl, const char* src, const char* tpl_name) {
    if (!tpl || !src) {
        return new jinja2cpp_result_t<void>(nonstd::make_unexpected(jinja2cpp_error_info_t()));
    }
    return new jinja2cpp_result_t<void>(tpl->Load(src, tpl_name ? std::string(tpl_name) : std::string()));
}

jinja2cpp_result_t<const char*>* jinja2cpp_render_as_string(jinja2cpp_template_t* tpl, const jinja2cpp_values_map_t* params) {
    if (!tpl || !params) {
        return new jinja2cpp_result_t<const char*>(nonstd::make_unexpected(jinja2cpp_error_info_t()));
    }

    auto result = tpl->RenderAsString(*params);
    if (result.has_value()) {
        char* result_cstr = strdup(result->c_str());
        return new jinja2cpp_result_t<const char*>(result_cstr);
    } else {
        return new jinja2cpp_result_t<const char*>(nonstd::make_unexpected(result.error()));
    }
}