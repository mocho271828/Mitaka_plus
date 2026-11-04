#pragma once
#include <cstdint>
#include <string>

namespace mitaka::gui {
// ローカル子プロセスの JSON フレーム。外部ネットワークには使わない。
// 上限超過・切断・I/O エラーは runtime_error、送信には SIGPIPE を発生させない。
inline constexpr std::uint32_t script_frame_limit = 65536;
std::string read_script_frame(int socket);
void write_script_frame(int socket, const std::string& text);
} // namespace mitaka::gui
