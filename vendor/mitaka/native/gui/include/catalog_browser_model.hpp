#pragma once

#include "extended_catalogs.hpp"
#include "sky_model.hpp"
#include <functional>
#include <memory>
#include <optional>
#include <string>

namespace mitaka::gui {

enum class BrowserObjectKind { planet, star, constellation, nebula, galaxy, quasar };
struct BrowserObjectReference { BrowserObjectKind kind; std::size_t index; };
struct BrowserEntryText { std::int64_t identifier; std::string title, details; };
struct BrowserSearchQuery {
    std::string text;
    std::optional<BrowserObjectKind> kind;
    std::size_t offset = 0, page_size = 500;
};
struct BrowserSearchPage {
    std::vector<BrowserObjectReference> rows;
    std::size_t total_matches = 0, total_objects = 0, offset = 0;
    bool cancelled = false;
};

// 元データを共有し、全件分の行・表示文字列を作らない。検索結果は指定ページだけ保持する。
// searchは背景スレッドで使用でき、cancelledがtrueの結果は表示へ適用しない。
class CatalogBrowserModel {
public:
    CatalogBrowserModel(std::shared_ptr<const SkyModel> model,
                        std::shared_ptr<const ExtendedCatalogs> catalogs);
    std::size_t size() const noexcept;
    BrowserSearchPage search(const BrowserSearchQuery& query,
                            const std::function<bool()>& cancelled = {}) const;
    // 可視行・選択行だけで呼び出す。参照が範囲外ならout_of_range。
    BrowserEntryText entry(BrowserObjectReference reference) const;

private:
    std::shared_ptr<const SkyModel> model_;
    std::shared_ptr<const ExtendedCatalogs> catalogs_;
    std::size_t count(BrowserObjectKind kind) const noexcept;
};
}
