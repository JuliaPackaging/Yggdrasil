/**
 * LibNTL Julia Wrapper
 *
 * CxxWrap-based wrapper for NTL (Number Theory Library) providing
 * Julia bindings for ZZ, ZZ_p, and ZZX types.
 */

#include <jlcxx/jlcxx.hpp>
#include <jlcxx/stl.hpp>

#include <NTL/ZZ.h>
#include <NTL/ZZ_p.h>
#include <NTL/ZZX.h>

#include <sstream>
#include <string>
#include <stdexcept>

using namespace NTL;

/**
 * Module entry point for CxxWrap
 *
 * This function defines all Julia bindings for NTL types.
 * Types and functions are registered here and become available
 * when the Julia module loads the shared library.
 */
JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    // =========================================================================
    // ZZ Type (Arbitrary-Precision Integers)
    // =========================================================================

    mod.add_type<ZZ>("ZZ")
        .constructor<>()
        .constructor<long>()
        .method("__copy__", [](const ZZ& a) { return ZZ(a); });

    // ZZ String Conversion
    mod.method("ZZ_from_string", [](const std::string& s) {
        ZZ z;
        std::istringstream iss(s);
        iss >> z;
        if (iss.fail()) {
            throw std::invalid_argument("Invalid integer string: " + s);
        }
        return z;
    });

    mod.method("ZZ_to_string", [](const ZZ& z) {
        std::ostringstream oss;
        oss << z;
        return oss.str();
    });

    // ZZ Arithmetic Operations
    mod.method("ZZ_add", [](const ZZ& a, const ZZ& b) { return a + b; });
    mod.method("ZZ_sub", [](const ZZ& a, const ZZ& b) { return a - b; });
    mod.method("ZZ_mul", [](const ZZ& a, const ZZ& b) { return a * b; });

    mod.method("ZZ_div", [](const ZZ& a, const ZZ& b) {
        if (IsZero(b)) throw std::domain_error("Division by zero");
        return a / b;
    });

    mod.method("ZZ_rem", [](const ZZ& a, const ZZ& b) {
        if (IsZero(b)) throw std::domain_error("Division by zero");
        return a % b;
    });

    mod.method("ZZ_divrem", [](const ZZ& a, const ZZ& b) {
        if (IsZero(b)) throw std::domain_error("Division by zero");
        ZZ q, r;
        DivRem(q, r, a, b);
        return std::make_tuple(q, r);
    });

    mod.method("ZZ_power", [](const ZZ& a, long e) {
        if (e < 0) throw std::domain_error("Negative exponent");
        return power(a, e);
    });

    mod.method("ZZ_negate", [](const ZZ& a) { return -a; });
    mod.method("ZZ_abs", [](const ZZ& a) { return abs(a); });

    // ZZ GCD Operations
    mod.method("ZZ_gcd", [](const ZZ& a, const ZZ& b) {
        return GCD(a, b);
    });

    mod.method("ZZ_gcdx", [](const ZZ& a, const ZZ& b) {
        ZZ d, s, t;
        XGCD(d, s, t, a, b);
        return std::make_tuple(d, s, t);
    });

    // ZZ Comparison Operations
    mod.method("ZZ_equal", [](const ZZ& a, const ZZ& b) { return a == b; });
    mod.method("ZZ_less", [](const ZZ& a, const ZZ& b) { return a < b; });
    mod.method("ZZ_lesseq", [](const ZZ& a, const ZZ& b) { return a <= b; });

    // ZZ Predicates
    mod.method("ZZ_iszero", [](const ZZ& a) { return IsZero(a); });
    mod.method("ZZ_isone", [](const ZZ& a) { return IsOne(a); });
    mod.method("ZZ_sign", [](const ZZ& a) { return sign(a); });
    mod.method("ZZ_isodd", [](const ZZ& a) { return IsOdd(a); });

    // ZZ Size Queries
    mod.method("ZZ_numbits", [](const ZZ& a) { return NumBits(a); });
    mod.method("ZZ_numbytes", [](const ZZ& a) { return NumBytes(a); });

    // =========================================================================
    // ZZ_p Type (Integers Modulo p)
    // =========================================================================

    mod.add_type<ZZ_p>("ZZ_p")
        .constructor<>()
        .constructor<long>()
        .method("__copy__", [](const ZZ_p& a) { return ZZ_p(a); });

    // ZZ_p Modulus Management
    mod.method("ZZ_p_init", [](const ZZ& p) {
        if (p <= 1) throw std::domain_error("Modulus must be > 1");
        ZZ_p::init(p);
    });

    mod.method("ZZ_p_modulus", []() {
        return ZZ_p::modulus();
    });

    // ZZ_pContext Type
    mod.add_type<ZZ_pContext>("ZZ_pContext")
        .constructor<>()
        .constructor<const ZZ&>();

    mod.method("ZZ_pContext_save", [](ZZ_pContext& ctx) {
        ctx.save();
    });

    mod.method("ZZ_pContext_restore", [](const ZZ_pContext& ctx) {
        ctx.restore();
    });

    // ZZ_p Representation
    mod.method("ZZ_p_rep", [](const ZZ_p& a) {
        return rep(a);
    });

    // ZZ_p Arithmetic Operations
    mod.method("ZZ_p_add", [](const ZZ_p& a, const ZZ_p& b) { return a + b; });
    mod.method("ZZ_p_sub", [](const ZZ_p& a, const ZZ_p& b) { return a - b; });
    mod.method("ZZ_p_mul", [](const ZZ_p& a, const ZZ_p& b) { return a * b; });
    mod.method("ZZ_p_negate", [](const ZZ_p& a) { return -a; });

    mod.method("ZZ_p_inv", [](const ZZ_p& a) {
        if (IsZero(a)) {
            throw std::domain_error("Inverse of zero");
        }
        return inv(a);
    });

    mod.method("ZZ_p_div", [](const ZZ_p& a, const ZZ_p& b) {
        if (IsZero(b)) {
            throw std::domain_error("Division by zero");
        }
        return a / b;
    });

    mod.method("ZZ_p_power", [](const ZZ_p& a, long e) {
        return power(a, e);
    });

    mod.method("ZZ_p_power_ZZ", [](const ZZ_p& a, const ZZ& e) {
        return power(a, e);
    });

    // ZZ_p Predicates
    mod.method("ZZ_p_iszero", [](const ZZ_p& a) { return IsZero(a); });
    mod.method("ZZ_p_isone", [](const ZZ_p& a) { return IsOne(a); });

    // =========================================================================
    // ZZX Type (Polynomials over Z)
    // =========================================================================

    mod.add_type<ZZX>("ZZX")
        .constructor<>()
        .constructor<long>()
        .constructor<const ZZ&>()
        .method("__copy__", [](const ZZX& f) { return ZZX(f); });

    // ZZX Coefficient Access
    mod.method("ZZX_deg", [](const ZZX& f) { return deg(f); });

    mod.method("ZZX_coeff", [](const ZZX& f, long i) {
        return coeff(f, i);
    });

    mod.method("ZZX_setcoeff", [](ZZX& f, long i, const ZZ& c) {
        SetCoeff(f, i, c);
    });

    mod.method("ZZX_leadcoeff", [](const ZZX& f) { return LeadCoeff(f); });
    mod.method("ZZX_constterm", [](const ZZX& f) { return ConstTerm(f); });

    // ZZX Arithmetic Operations
    mod.method("ZZX_add", [](const ZZX& f, const ZZX& g) { return f + g; });
    mod.method("ZZX_sub", [](const ZZX& f, const ZZX& g) { return f - g; });
    mod.method("ZZX_mul", [](const ZZX& f, const ZZX& g) { return f * g; });
    mod.method("ZZX_mul_scalar", [](const ZZ& c, const ZZX& f) { return c * f; });
    mod.method("ZZX_negate", [](const ZZX& f) { return -f; });

    mod.method("ZZX_div", [](const ZZX& f, const ZZX& g) {
        if (IsZero(g)) throw std::domain_error("Division by zero polynomial");
        return f / g;
    });

    mod.method("ZZX_rem", [](const ZZX& f, const ZZX& g) {
        if (IsZero(g)) throw std::domain_error("Division by zero polynomial");
        return f % g;
    });

    mod.method("ZZX_divrem", [](const ZZX& f, const ZZX& g) {
        if (IsZero(g)) throw std::domain_error("Division by zero polynomial");
        ZZX q, r;
        DivRem(q, r, f, g);
        return std::make_tuple(q, r);
    });

    mod.method("ZZX_gcd", [](const ZZX& f, const ZZX& g) {
        return GCD(f, g);
    });

    // ZZX Polynomial Operations
    mod.method("ZZX_diff", [](const ZZX& f) {
        ZZX df;
        diff(df, f);
        return df;
    });

    mod.method("ZZX_content", [](const ZZX& f) {
        ZZ c;
        content(c, f);
        return c;
    });

    mod.method("ZZX_primpart", [](const ZZX& f) {
        ZZX pp;
        PrimitivePart(pp, f);
        return pp;
    });

    mod.method("ZZX_eval", [](const ZZX& f, const ZZ& x) {
        // Horner's method for polynomial evaluation
        if (IsZero(f)) return ZZ(0);
        long d = deg(f);
        ZZ result = coeff(f, d);
        for (long i = d - 1; i >= 0; i--) {
            result = result * x + coeff(f, i);
        }
        return result;
    });

    // ZZX Predicates and Conversion
    mod.method("ZZX_iszero", [](const ZZX& f) { return IsZero(f); });

    mod.method("ZZX_to_string", [](const ZZX& f) {
        std::ostringstream oss;
        oss << f;
        return oss.str();
    });
}
