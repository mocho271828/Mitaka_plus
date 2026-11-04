#pragma once
#import <Foundation/Foundation.h>

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>

namespace mitaka::gui {

inline constexpr std::size_t html_document_limit = 1024 * 1024;
inline constexpr std::size_t html_script_limit = 64 * 1024;

struct HtmlDocumentIdentity {
    std::string canonical_path;
    std::array<unsigned char, 32> digest{};
    std::uint64_t device = 0;
    std::uint64_t inode = 0;
};

struct HtmlDocumentSnapshot {
    HtmlDocumentIdentity identity;
    NSData *data = nil;
};

// 信頼した内容と表示する bytes を同じ bounded read から得る。
HtmlDocumentSnapshot read_html_document(NSURL *url);

// 通常のローカル HTML を上限付きで読み、実体パス・inode・内容を照合する。
// 読み込み中の変更、不正 URL、欠損、非通常ファイルでは例外を返す。
HtmlDocumentIdentity inspect_html_document(NSURL *url);

struct HtmlBridgeRequest {
    NSString *url = nil;
    NSURL *source_url = nil;
    NSURL *document_url = nil;
    bool source_main_frame = false;
    bool target_main_frame = false;
    bool has_target_frame = false;
    bool link_activated = false;
};

enum class HtmlBridgeDisposition { navigation, rejected, script };
struct HtmlBridgeResult {
    HtmlBridgeDisposition disposition = HtmlBridgeDisposition::rejected;
    std::string script;
    std::string error;
};

// UI の明示承認後に trust を呼ぶ。WebKit の資産取得制限やユーザー承認は担当しない。
// 通常遷移を判定した時点で失効し、遷移取消・再読込・戻る操作でも復活しない。
class HtmlBridgePolicy {
public:
    void trust(const HtmlDocumentIdentity& document);
    void revoke() { trusted_.reset(); }
    bool trusted() const { return trusted_.has_value(); }
    HtmlBridgeResult evaluate(const HtmlBridgeRequest& request);
private:
    std::optional<HtmlDocumentIdentity> trusted_;
};

} // namespace mitaka::gui
