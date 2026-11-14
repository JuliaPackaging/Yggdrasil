#include "tigre_julia_runtime.hpp"

#include <string>

namespace {
thread_local std::string g_last_error_message;
thread_local std::string g_last_error_tag;
}  // namespace

TigreJuliaError::TigreJuliaError(const char* tag, const char* message)
    : std::runtime_error(message == nullptr ? "unknown TIGRE error" : message),
      m_tag(tag == nullptr ? "" : tag) {}

const char* TigreJuliaError::tag() const noexcept {
    return m_tag;
}

void tigre_julia_set_last_error(const char* tag, const char* message) noexcept {
    g_last_error_tag = tag == nullptr ? "" : tag;
    g_last_error_message = message == nullptr ? "" : message;
}

extern "C" void tigre_julia_clear_last_error(void) noexcept {
    g_last_error_tag.clear();
    g_last_error_message.clear();
}

extern "C" const char* tigre_julia_last_error_message(void) noexcept {
    return g_last_error_message.c_str();
}

extern "C" const char* tigre_julia_last_error_tag(void) noexcept {
    return g_last_error_tag.c_str();
}

[[noreturn]] void tigre_julia_throw(const char* tag, const char* message) {
    tigre_julia_set_last_error(tag, message);
    throw TigreJuliaError(tag, message);
}
