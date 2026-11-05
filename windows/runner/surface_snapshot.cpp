#include "surface_snapshot.h"

#include <windows.h>

#include <cstdlib>
#include <cstring>
#include <utility>

namespace {

constexpr int kKnownSchema = 1;
constexpr int kMaxJsonDepth = 16;
constexpr char kSurfaceScheme[] = "starter-surface:";

std::wstring Wide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int length = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                           static_cast<int>(utf8.size()),
                                           nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring wide(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                        wide.data(), length);
  return wide;
}

struct Json {
  enum class Type { kNull, kBool, kNumber, kString, kArray, kObject };

  Type type = Type::kNull;
  double number = 0;
  std::string text;
  // Array items, or object values with their names in |keys|.
  std::vector<Json> items;
  std::vector<std::string> keys;

  const Json* Find(const char* key) const {
    for (size_t i = 0; i < keys.size(); ++i) {
      if (keys[i] == key) {
        return &items[i];
      }
    }
    return nullptr;
  }

  std::string StringAt(const char* key) const {
    const Json* found = Find(key);
    return found && found->type == Type::kString ? found->text : std::string();
  }
};

// A small strict JSON reader. The Windows embedder ships no JSON library, and
// this file can be edited by anything running as the user, so it fails closed.
class JsonReader {
 public:
  explicit JsonReader(const std::string& text)
      : cursor_(text.c_str()), end_(text.c_str() + text.size()) {}

  bool ReadDocument(Json* out) {
    if (!ReadValue(out, 0)) {
      return false;
    }
    SkipSpace();
    return cursor_ == end_;
  }

 private:
  void SkipSpace() {
    while (cursor_ < end_ && (*cursor_ == ' ' || *cursor_ == '\n' ||
                              *cursor_ == '\r' || *cursor_ == '\t')) {
      ++cursor_;
    }
  }

  bool Consume(char expected) {
    SkipSpace();
    if (cursor_ < end_ && *cursor_ == expected) {
      ++cursor_;
      return true;
    }
    return false;
  }

  bool ConsumeWord(const char* word) {
    const size_t length = std::strlen(word);
    if (static_cast<size_t>(end_ - cursor_) < length ||
        std::strncmp(cursor_, word, length) != 0) {
      return false;
    }
    cursor_ += length;
    return true;
  }

  bool ReadValue(Json* out, int depth) {
    if (depth > kMaxJsonDepth) {
      return false;
    }
    SkipSpace();
    if (cursor_ >= end_) {
      return false;
    }
    switch (*cursor_) {
      case '{':
        return ReadObject(out, depth);
      case '[':
        return ReadArray(out, depth);
      case '"':
        out->type = Json::Type::kString;
        return ReadString(&out->text);
      case 't':
        out->type = Json::Type::kBool;
        out->number = 1;
        return ConsumeWord("true");
      case 'f':
        out->type = Json::Type::kBool;
        return ConsumeWord("false");
      case 'n':
        return ConsumeWord("null");
      default:
        return ReadNumber(out);
    }
  }

  bool ReadObject(Json* out, int depth) {
    out->type = Json::Type::kObject;
    ++cursor_;
    if (Consume('}')) {
      return true;
    }
    do {
      SkipSpace();
      std::string key;
      Json value;
      if (cursor_ >= end_ || *cursor_ != '"' || !ReadString(&key) ||
          !Consume(':') || !ReadValue(&value, depth + 1)) {
        return false;
      }
      out->keys.push_back(std::move(key));
      out->items.push_back(std::move(value));
    } while (Consume(','));
    return Consume('}');
  }

  bool ReadArray(Json* out, int depth) {
    out->type = Json::Type::kArray;
    ++cursor_;
    if (Consume(']')) {
      return true;
    }
    do {
      Json value;
      if (!ReadValue(&value, depth + 1)) {
        return false;
      }
      out->items.push_back(std::move(value));
    } while (Consume(','));
    return Consume(']');
  }

  bool ReadNumber(Json* out) {
    // strtod also takes "inf", "nan" and hex, none of which are JSON.
    if (*cursor_ != '-' && (*cursor_ < '0' || *cursor_ > '9')) {
      return false;
    }
    char* parsed_end = nullptr;
    out->type = Json::Type::kNumber;
    out->number = std::strtod(cursor_, &parsed_end);
    if (parsed_end == cursor_ || parsed_end > end_) {
      return false;
    }
    cursor_ = parsed_end;
    return true;
  }

  bool ReadHex4(unsigned int* out) {
    if (end_ - cursor_ < 4) {
      return false;
    }
    unsigned int value = 0;
    for (int i = 0; i < 4; ++i) {
      const char c = *cursor_++;
      value <<= 4;
      if (c >= '0' && c <= '9') {
        value |= static_cast<unsigned int>(c - '0');
      } else if (c >= 'a' && c <= 'f') {
        value |= static_cast<unsigned int>(c - 'a' + 10);
      } else if (c >= 'A' && c <= 'F') {
        value |= static_cast<unsigned int>(c - 'A' + 10);
      } else {
        return false;
      }
    }
    *out = value;
    return true;
  }

  static void AppendUtf8(unsigned int code, std::string* out) {
    if (code < 0x80) {
      out->push_back(static_cast<char>(code));
    } else if (code < 0x800) {
      out->push_back(static_cast<char>(0xC0 | (code >> 6)));
      out->push_back(static_cast<char>(0x80 | (code & 0x3F)));
    } else if (code < 0x10000) {
      out->push_back(static_cast<char>(0xE0 | (code >> 12)));
      out->push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
      out->push_back(static_cast<char>(0x80 | (code & 0x3F)));
    } else {
      out->push_back(static_cast<char>(0xF0 | (code >> 18)));
      out->push_back(static_cast<char>(0x80 | ((code >> 12) & 0x3F)));
      out->push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
      out->push_back(static_cast<char>(0x80 | (code & 0x3F)));
    }
  }

  bool ReadEscape(std::string* out) {
    if (cursor_ >= end_) {
      return false;
    }
    const char escape = *cursor_++;
    switch (escape) {
      case '"':
      case '\\':
      case '/':
        out->push_back(escape);
        return true;
      case 'b':
        out->push_back('\b');
        return true;
      case 'f':
        out->push_back('\f');
        return true;
      case 'n':
        out->push_back('\n');
        return true;
      case 'r':
        out->push_back('\r');
        return true;
      case 't':
        out->push_back('\t');
        return true;
      case 'u':
        break;
      default:
        return false;
    }
    unsigned int code = 0;
    if (!ReadHex4(&code)) {
      return false;
    }
    if (code >= 0xD800 && code <= 0xDBFF) {
      unsigned int low = 0;
      if (end_ - cursor_ < 6 || cursor_[0] != '\\' || cursor_[1] != 'u') {
        return false;
      }
      cursor_ += 2;
      if (!ReadHex4(&low) || low < 0xDC00 || low > 0xDFFF) {
        return false;
      }
      code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00);
    } else if (code >= 0xDC00 && code <= 0xDFFF) {
      return false;
    }
    AppendUtf8(code, out);
    return true;
  }

  bool ReadString(std::string* out) {
    ++cursor_;
    while (cursor_ < end_) {
      const char c = *cursor_++;
      if (c == '"') {
        return true;
      }
      if (static_cast<unsigned char>(c) < 0x20) {
        return false;
      }
      if (c != '\\') {
        out->push_back(c);
      } else if (!ReadEscape(out)) {
        return false;
      }
    }
    return false;
  }

  const char* cursor_;
  const char* end_;
};

int HexDigit(char c) {
  if (c >= '0' && c <= '9') {
    return c - '0';
  }
  if (c >= 'a' && c <= 'f') {
    return c - 'a' + 10;
  }
  if (c >= 'A' && c <= 'F') {
    return c - 'A' + 10;
  }
  return -1;
}

std::string PercentDecode(const std::string& text) {
  std::string decoded;
  decoded.reserve(text.size());
  for (size_t i = 0; i < text.size(); ++i) {
    if (text[i] == '%' && i + 2 < text.size() && HexDigit(text[i + 1]) >= 0 &&
        HexDigit(text[i + 2]) >= 0) {
      decoded.push_back(
          static_cast<char>(HexDigit(text[i + 1]) * 16 + HexDigit(text[i + 2])));
      i += 2;
    } else {
      decoded.push_back(text[i]);
    }
  }
  return decoded;
}

}  // namespace

SurfaceSnapshot SurfaceSnapshot::Fallback() {
  SurfaceSnapshot snapshot;
  snapshot.title = L"Starter";
  snapshot.subtitle = L"Open the app to get started";
  return snapshot;
}

SurfaceSnapshot SurfaceSnapshot::Parse(const std::string& json) {
  Json root;
  if (!JsonReader(json).ReadDocument(&root) ||
      root.type != Json::Type::kObject) {
    return Fallback();
  }
  const Json* schema = root.Find("schema");
  const std::string title = root.StringAt("title");
  if (!schema || schema->type != Json::Type::kNumber ||
      schema->number > kKnownSchema || title.empty()) {
    return Fallback();
  }

  SurfaceSnapshot snapshot;
  snapshot.title = Wide(title);
  snapshot.subtitle = Wide(root.StringAt("subtitle"));
  snapshot.value = Wide(root.StringAt("value"));
  snapshot.value_label = Wide(root.StringAt("valueLabel"));
  snapshot.route = root.StringAt("route");
  const Json* actions = root.Find("actions");
  if (actions && actions->type == Json::Type::kArray) {
    for (const Json& action : actions->items) {
      const std::string label = action.StringAt("label");
      const std::string route = action.StringAt("route");
      if (!label.empty() && !route.empty()) {
        snapshot.actions.push_back(SurfaceAction{Wide(label), route});
      }
    }
  }
  return snapshot;
}

std::wstring SurfaceSnapshot::Tooltip(size_t max_length) const {
  std::wstring tooltip = title;
  if (!subtitle.empty()) {
    tooltip += L"\n" + subtitle;
  }
  if (!value.empty()) {
    tooltip += L"\n" + value;
    if (!value_label.empty()) {
      tooltip += L" " + value_label;
    }
  }
  if (tooltip.size() > max_length) {
    tooltip.resize(max_length);
    // Never leave half of a surrogate pair at the end.
    if (IS_HIGH_SURROGATE(tooltip.back())) {
      tooltip.pop_back();
    }
  }
  return tooltip;
}

bool IsSurfaceUrl(const std::string& argument) {
  return _strnicmp(argument.c_str(), kSurfaceScheme,
                   std::strlen(kSurfaceScheme)) == 0;
}

std::string RouteFromSurfaceUrl(const std::string& url) {
  if (!IsSurfaceUrl(url)) {
    return std::string();
  }
  const size_t query_start = url.find('?');
  if (query_start == std::string::npos) {
    return std::string();
  }
  const std::string query =
      url.substr(query_start + 1, url.find('#', query_start) - query_start - 1);
  size_t start = 0;
  while (start <= query.size()) {
    size_t end = query.find('&', start);
    if (end == std::string::npos) {
      end = query.size();
    }
    const std::string pair = query.substr(start, end - start);
    if (pair.rfind("route=", 0) == 0) {
      return PercentDecode(pair.substr(6));
    }
    start = end + 1;
  }
  return std::string();
}
