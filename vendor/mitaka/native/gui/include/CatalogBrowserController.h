#import <AppKit/AppKit.h>
#include "extended_catalogs.hpp"
#include "sky_model.hpp"
#include <memory>

typedef NS_ENUM(NSInteger, CatalogObjectKind) {
    CatalogObjectPlanet, CatalogObjectStar, CatalogObjectConstellation,
    CatalogObjectNebula, CatalogObjectGalaxy, CatalogObjectQuasar
};

@interface CatalogBrowserEntry : NSObject
@property(nonatomic) CatalogObjectKind kind;
@property(nonatomic) NSInteger identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *details;
@end

@interface CatalogBrowserController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(CatalogBrowserEntry *entry, BOOL center);
// 星座の元行 index を使う。チェック変更は選択・中央移動を伴わない。
@property(nonatomic, copy) BOOL (^constellationVisible)(NSUInteger row);
@property(nonatomic, copy) void (^setConstellationVisible)(NSUInteger row, BOOL visible);
@property(nonatomic, copy) void (^setAllConstellationsVisible)(BOOL visible);
@property(nonatomic, copy) BOOL (^starNameSelectable)(NSInteger hip);
@property(nonatomic, copy) BOOL (^starNameSelected)(NSInteger hip);
@property(nonatomic, copy) void (^setStarNameSelected)(NSInteger hip, BOOL selected);
@property(nonatomic, copy) void (^setAllStarNamesSelected)(BOOL selected);
- (void)refreshConstellationVisibility;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
    extendedCatalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
@end
