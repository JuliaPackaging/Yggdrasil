#include "template_env_wrap.h"

jinja2cpp_template_env_t* jinja2cpp_template_env_create() {
    return new jinja2cpp_template_env_t();
}

void jinja2cpp_template_env_destroy(jinja2cpp_template_env_t* env) {
    delete env;
}

// void jinja2cpp_template_env_add_filesystem_handler(jinja2cpp_template_env_t* env, const char* prefix, jinja2cpp_memory_file_system_t* handler) {
//     if (!env || !prefix || !handler) return;
//     env->AddFilesystemHandler(prefix, std::shared_ptr<jinja2cpp_memory_file_system_t>(handler));
// }

void jinja2cpp_template_env_add_filesystem_handler(jinja2cpp_template_env_t* env, const char* prefix, jinja2cpp_memory_file_system_t* handler) {
    if (!env || !prefix || !handler) return;
    env->AddFilesystemHandler(std::string(prefix), *handler);
}

jinja2cpp_result_t<jinja2cpp_template_t*>* jinja2cpp_template_env_load_template(jinja2cpp_template_env_t* env, const char* fileName) {
    if (!env || !fileName) {
        return new jinja2cpp_result_t<jinja2cpp_template_t*>(nonstd::make_unexpected(jinja2cpp_error_info_t()));
    }
    auto templateResult = env->LoadTemplate(fileName);
    if (!templateResult.has_value()) {
        return new jinja2cpp_result_t<jinja2cpp_template_t*>(nonstd::make_unexpected(templateResult.error()));
    }

    return new jinja2cpp_result_t<jinja2cpp_template_t*>(new jinja2cpp_template_t(std::move(templateResult.value())));
}

void jinja2cpp_template_env_add_global(jinja2cpp_template_env_t* env, const char* name, jinja2cpp_value_t* value) {
    if (!env || !name || !value) return;
    env->AddGlobal(name, *value);
}

void jinja2cpp_template_env_remove_global(jinja2cpp_template_env_t* env, const char* name) {
    if (!env || !name) return;
    env->RemoveGlobal(name);
}