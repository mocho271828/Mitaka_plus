#include "script_transport.hpp"
#include <arpa/inet.h>
#include <cerrno>
#include <cstring>
#include <stdexcept>
#include <sys/socket.h>

namespace mitaka::gui {
namespace {
void transfer(int socket, void *data, std::size_t size, bool writing) {
    auto *bytes = static_cast<char *>(data);
    while (size != 0) {
        const auto count = writing ? ::send(socket, bytes, size, 0) : ::recv(socket, bytes, size, 0);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) throw std::runtime_error(count == 0 ? "Script connection closed" : std::strerror(errno));
        bytes += count;
        size -= static_cast<std::size_t>(count);
    }
}
}
std::string read_script_frame(int socket) {
    std::uint32_t size;
    transfer(socket, &size, sizeof(size), false);
    size = ntohl(size);
    if (size == 0 || size > script_frame_limit) throw std::runtime_error("Invalid script frame size");
    std::string text(size, '\0');
    transfer(socket, text.data(), size, false);
    return text;
}
void write_script_frame(int socket, const std::string& text) {
    if (text.empty() || text.size() > script_frame_limit) throw std::runtime_error("Invalid script frame size");
    const int enabled = 1;
    if (setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &enabled, sizeof(enabled)) != 0)
        throw std::runtime_error("Cannot configure script connection");
    std::uint32_t size = htonl(static_cast<std::uint32_t>(text.size()));
    transfer(socket, &size, sizeof(size), true);
    transfer(socket, const_cast<char *>(text.data()), text.size(), true);
}
} // namespace mitaka::gui
