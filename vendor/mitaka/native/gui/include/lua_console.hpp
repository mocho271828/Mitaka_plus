#pragma once
#include <lua.hpp>
#include <string_view>

namespace mitaka::gui {
// 空のスタックで呼ぶ。成功時は表示用文字列（戻り値なしなら空文字列）、失敗時はエラーを残す。
// Lua の呼出しと文字列化は保護モードで行い、入力の行番号を変えない。
int execute_console_source(lua_State *state, std::string_view source, lua_CFunction traceback);
} // namespace mitaka::gui
