#ifndef TIGRE_JULIA_RUNTIME_HPP
#define TIGRE_JULIA_RUNTIME_HPP

#include <stdexcept>

class TigreJuliaError : public std::runtime_error {
public:
    TigreJuliaError(const char* tag, const char* message);
    const char* tag() const noexcept;

private:
    const char* m_tag;
};

void tigre_julia_set_last_error(const char* tag, const char* message) noexcept;
extern "C" void tigre_julia_clear_last_error(void) noexcept;
extern "C" const char* tigre_julia_last_error_message(void) noexcept;
extern "C" const char* tigre_julia_last_error_tag(void) noexcept;
[[noreturn]] void tigre_julia_throw(const char* tag, const char* message);

#endif
