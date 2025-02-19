#include "jlcxx/jlcxx.hpp"
#include <jinja2cpp/template.h>

namespace jinja2 {

using ExpectedString = nonstd::expected<std::string, ErrorInfo>;

struct WrappedExpectedString {
    ExpectedString result;

    bool has_value() const {
        return result.has_value();
    }

    std::string value() const {
        if (!result.has_value()) {
            throw std::runtime_error("Called value() on an error result");
        }
        return result.value();
    }

    ErrorInfo error() const {
        if (result.has_value()) {
            throw std::runtime_error("Called error() on a valid result");
        }
        return result.error();
    }
};

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    using jinja2::Value;
    using jinja2::ValuesMap;
    using jinja2::ErrorInfo;

    mod.add_bits<ErrorCode>("ErrorCode", jlcxx::julia_type("CppEnum"));
    mod.set_const("Unspecified", ErrorCode::Unspecified);
    mod.set_const("UnexpectedException", ErrorCode::UnexpectedException);
    mod.set_const("YetUnsupported", ErrorCode::YetUnsupported);
    mod.set_const("FileNotFound", ErrorCode::FileNotFound);
    mod.set_const("ExtensionDisabled", ErrorCode::ExtensionDisabled);
    mod.set_const("TemplateEnvAbsent", ErrorCode::TemplateEnvAbsent);
    mod.set_const("TemplateNotFound", ErrorCode::TemplateNotFound);
    mod.set_const("TemplateNotParsed", ErrorCode::TemplateNotParsed);
    mod.set_const("InvalidValueType", ErrorCode::InvalidValueType);
    mod.set_const("InvalidTemplateName", ErrorCode::InvalidTemplateName);
    mod.set_const("MetadataParseError", ErrorCode::MetadataParseError);
    mod.set_const("ExpectedStringLiteral", ErrorCode::ExpectedStringLiteral);
    mod.set_const("ExpectedIdentifier", ErrorCode::ExpectedIdentifier);
    mod.set_const("ExpectedSquareBracket", ErrorCode::ExpectedSquareBracket);
    mod.set_const("ExpectedRoundBracket", ErrorCode::ExpectedRoundBracket);
    mod.set_const("ExpectedCurlyBracket", ErrorCode::ExpectedCurlyBracket);
    mod.set_const("ExpectedToken", ErrorCode::ExpectedToken);
    mod.set_const("ExpectedExpression", ErrorCode::ExpectedExpression);
    mod.set_const("ExpectedEndOfStatement", ErrorCode::ExpectedEndOfStatement);
    mod.set_const("ExpectedRawEnd", ErrorCode::ExpectedRawEnd);
    mod.set_const("ExpectedMetaEnd", ErrorCode::ExpectedMetaEnd);
    mod.set_const("UnexpectedToken", ErrorCode::UnexpectedToken);
    mod.set_const("UnexpectedStatement", ErrorCode::UnexpectedStatement);
    mod.set_const("UnexpectedCommentBegin", ErrorCode::UnexpectedCommentBegin);
    mod.set_const("UnexpectedCommentEnd", ErrorCode::UnexpectedCommentEnd);
    mod.set_const("UnexpectedExprBegin", ErrorCode::UnexpectedExprBegin);
    mod.set_const("UnexpectedExprEnd", ErrorCode::UnexpectedExprEnd);
    mod.set_const("UnexpectedStmtBegin", ErrorCode::UnexpectedStmtBegin);
    mod.set_const("UnexpectedStmtEnd", ErrorCode::UnexpectedStmtEnd);
    mod.set_const("UnexpectedRawBegin", ErrorCode::UnexpectedRawBegin);
    mod.set_const("UnexpectedRawEnd", ErrorCode::UnexpectedRawEnd);
    mod.set_const("UnexpectedMetaBegin", ErrorCode::UnexpectedMetaBegin);
    mod.set_const("UnexpectedMetaEnd", ErrorCode::UnexpectedMetaEnd);

    mod.add_type<ErrorInfo>("ErrorInfo")
        .constructor<>()
        .method("GetCode", &ErrorInfo::GetCode)
        .method("ToString", &ErrorInfo::ToString);

    mod.add_type<ValuesMap>("ValuesMap")
        .constructor<>()
        .method("set", [](ValuesMap& map, const std::string& key, const std::string& val) { 
            map[key] = Value(val); 
        })
        .method("set", [](ValuesMap& map, const std::string& key, const std::vector<std::string>& val) { 
            std::vector<Value> converted;
            converted.reserve(val.size());
            for (const auto& item : val) {
                converted.emplace_back(item);
            }
            map[key] = Value(std::move(converted));
        })
        .method("set", [](jinja2::ValuesMap& map, const std::string& key, int val) { 
            map[key] = jinja2::Value(val); 
        })
        .method("set", [](jinja2::ValuesMap& map, const std::string& key, const std::vector<int>& val) { 
            std::vector<jinja2::Value> converted;
            converted.reserve(val.size());
            for (int item : val) {
                converted.emplace_back(item);
            }
            map[key] = jinja2::Value(std::move(converted));
        })
        .method("set", [](jinja2::ValuesMap& map, const std::string& key, double val) { 
            map[key] = jinja2::Value(val); 
        })
        .method("set", [](jinja2::ValuesMap& map, const std::string& key, const std::vector<double>& val) { 
            std::vector<jinja2::Value> converted;
            converted.reserve(val.size());
            for (double item : val) {
                converted.emplace_back(item);
            }
            map[key] = jinja2::Value(std::move(converted));
        })
        .method("get", [](const ValuesMap& map, const std::string& key) -> std::string {
            return map.at(key).asString();
        });

    mod.add_type<WrappedExpectedString>("ExpectedString")
        .constructor<>()
        .method("has_value", &WrappedExpectedString::has_value)
        .method("value", &WrappedExpectedString::value)
        .method("error", &WrappedExpectedString::error);

    mod.add_type<Template>("Template")
        .constructor<>()
        .method("delete", [](Template* tpl) { delete tpl; })
        .method("Load", [](Template& tpl, const char * data, std::string tplName) { 
            tpl.Load(data, tplName);  return tpl; 
        })
        .method("LoadFromFile", [](Template& tpl, const std::string& fileName) {
            tpl.LoadFromFile(fileName); return tpl;
        })
        .method("RenderAsString", [](Template& tpl, const ValuesMap& params) {
            return WrappedExpectedString{tpl.RenderAsString(params)};
        })
        .method("IsEqual", [](const Template& tpl, const Template& other) {
            return tpl.IsEqual(other);
        });
}

} // namespace jinja2