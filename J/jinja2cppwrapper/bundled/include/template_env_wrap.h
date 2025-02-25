#ifndef TEMPLATE_ENV_WRAP_H
#define TEMPLATE_ENV_WRAP_H 

#ifdef __cplusplus
#include <jinja2cpp/template_env.h>
#include "filesystem_handler_wrap.h"
#include "template_wrap.h"
#include <stddef.h>
#include <memory>
#include <string>

using jinja2cpp_template_env_t = jinja2::TemplateEnv;

extern "C" {
#endif

jinja2cpp_template_env_t* jinja2cpp_template_env_create();

void jinja2cpp_template_env_destroy(jinja2cpp_template_env_t* env);

void jinja2cpp_template_env_add_filesystem_handler(jinja2cpp_template_env_t* env, const char* prefix, jinja2cpp_memory_file_system_t* handler);

jinja2cpp_result_t<jinja2cpp_template_t*>* jinja2cpp_template_env_load_template(jinja2cpp_template_env_t* env, const char* fileName);

void jinja2cpp_template_env_add_global(jinja2cpp_template_env_t* env, const char* name, jinja2cpp_value_t* value);

void jinja2cpp_template_env_remove_global(jinja2cpp_template_env_t* env, const char* name);

#ifdef __cplusplus
}
#endif

#endif // TEMPLATE_ENV_WRAP_H