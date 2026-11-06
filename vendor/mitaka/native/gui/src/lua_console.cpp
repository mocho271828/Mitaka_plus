#include "lua_console.hpp"
#include <algorithm>
#include <cstring>
#include <string>

namespace mitaka::gui {
namespace {
constexpr std::size_t outputLimit = 8192;
constexpr char truncatedSuffix[] = "... [truncated]";

int formatResults(lua_State *state) {
    // __tostring とメモリ確保は longjmp し得るため、このフレームには所有オブジェクトを置かない。
    char output[outputLimit + sizeof(truncatedSuffix)]{};
    std::size_t used = 0;
    bool truncated = false;
    const int count = lua_gettop(state);
    if (count > 0) { std::memcpy(output, "=> ", 3); used = 3; }
    for (int index = 1; index <= count; ++index) {
        if (used == outputLimit) { truncated = true; break; }
        if (index > 1) output[used++] = '\t';
        std::size_t size = 0;
        const char *value = luaL_tolstring(state, index, &size);
        std::size_t copied = std::min(size, outputLimit - used);
        if (copied < size) {
            truncated = true;
            // 正常な UTF-8 の末尾だけを切ったことで出力全体が読めなくなるのを避ける。
            while (copied > 0 && (static_cast<unsigned char>(value[copied]) & 0xc0) == 0x80) --copied;
        }
        std::memcpy(output + used, value, copied);
        used += copied;
        lua_pop(state, 1);
        if (truncated) break;
    }
    if (truncated) {
        std::memcpy(output + used, truncatedSuffix, sizeof(truncatedSuffix) - 1);
        used += sizeof(truncatedSuffix) - 1;
    }
    lua_pushlstring(state, output, used);
    return 1;
}
}

int execute_console_source(lua_State *state, std::string_view source, lua_CFunction traceback) {
    // 公式 Lua の対話処理と同様に式を先に試す。コンパイルだけなので二重実行しない。
    const std::string expression = "return " + std::string(source);
    int status = luaL_loadbufferx(state, expression.data(), expression.size(), "@console.lua", "t");
    if (status == LUA_ERRSYNTAX) {
        lua_pop(state, 1);
        status = luaL_loadbufferx(state, source.data(), source.size(), "@console.lua", "t");
    }
    if (status != LUA_OK) return status;
    lua_pushcfunction(state, traceback);
    lua_insert(state, 1);
    status = lua_pcall(state, 0, LUA_MULTRET, 1);
    if (status == LUA_OK) {
        const int count = lua_gettop(state) - 1;
        lua_pushcfunction(state, formatResults);
        lua_insert(state, 2);
        status = lua_pcall(state, count, 1, 1);
    }
    lua_remove(state, 1);
    return status;
}
} // namespace mitaka::gui
