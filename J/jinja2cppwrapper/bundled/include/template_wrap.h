#ifndef TEMPLATE_C_H
#define TEMPLATE_C_H

#ifdef __cplusplus
#include "jinja2cpp/template.h"
#include <stddef.h>
#include "result_wrap.h"
#include "value_wrap.h"

using jinja2cpp_template_t = jinja2::Template;

extern "C" {
#endif

jinja2cpp_template_t* jinja2cpp_template_create();
void jinja2cpp_template_destroy(jinja2cpp_template_t* tpl);

jinja2cpp_result_t<void>* jinja2cpp_load(jinja2cpp_template_t* tpl, const char* src, const char* tpl_name);
jinja2cpp_result_t<const char*>* jinja2cpp_render_as_string(jinja2cpp_template_t* tpl, const jinja2cpp_values_map_t* params);

#ifdef __cplusplus
}
#endif

#endif // TEMPLATE_C_H