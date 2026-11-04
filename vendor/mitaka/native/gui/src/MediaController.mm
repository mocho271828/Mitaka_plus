#import "MediaController.h"
#import "MediaImageView.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#include "local_image.hpp"
#include "media_catalog.hpp"
#include <cstring>
#include <map>
#include <sys/stat.h>

using namespace mitaka::gui;
namespace {
char itemStatusContext;
NSString *text(const std::string& value) {
    NSString *result = [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding];
    return result ? result : @"文字コードエラー";
}
BOOL fail(NSError **error, NSString *message) {
    if (error) *error = [NSError errorWithDomain:@"org.mitaka.media" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
    return NO;
}
NSString *kindName(MediaKind kind) {
    switch (kind) {
        case MediaKind::image: return @"画像";
        case MediaKind::movie: return @"動画";
        case MediaKind::audio: return @"音声";
        case MediaKind::unknown: return @"旧形式未確定";
    }
}
NSStackView *stack(NSArray<NSView *> *views, BOOL vertical) {
    NSStackView *result = [NSStackView stackViewWithViews:views];
    result.orientation = vertical ? NSUserInterfaceLayoutOrientationVertical : NSUserInterfaceLayoutOrientationHorizontal;
    result.spacing = 10; return result;
}
void fill(NSView *child, NSView *parent, CGFloat inset) {
    child.translatesAutoresizingMaskIntoConstraints = NO;
    [parent addSubview:child];
    [NSLayoutConstraint activateConstraints:@[
        [child.leadingAnchor constraintEqualToAnchor:parent.leadingAnchor constant:inset],
        [child.trailingAnchor constraintEqualToAnchor:parent.trailingAnchor constant:-inset],
        [child.topAnchor constraintEqualToAnchor:parent.topAnchor constant:inset],
        [child.bottomAnchor constraintEqualToAnchor:parent.bottomAnchor constant:-inset]]];
}
NSWindow *makeWindow(NSString *title, NSSize size) {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, size.width, size.height)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    window.title = title; window.releasedWhenClosed = NO;
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    [window center]; return window;
}
}

@implementation MediaController {
    MediaCatalog _catalog;
    std::map<std::size_t, std::filesystem::path> _mappings;
    NSTableView *_table;
    NSTextField *_status, *_details, *_previewStatus;
    NSButton *_show, *_map, *_previous, *_next;
    NSWindow *_preview;
    MediaImageView *_imageView;
    AVPlayerView *_playerView;
    AVPlayerItem *_playerItem;
    NSStackView *_imageControls;
    NSSlider *_zoom, *_rotation, *_opacity;
    std::uint64_t _generation;
}
- (instancetype)init {
    if ((self = [super initWithWindow:makeWindow(@"ローカル媒体", NSMakeSize(800, 520))])) {
        self.window.minSize = NSMakeSize(620, 380); self.window.delegate = self;
        _table = [[NSTableView alloc] init];
        for (NSString *identifier in @[@"title", @"kind", @"state"]) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
            column.title = [identifier isEqualToString:@"title"] ? @"登録名" : ([identifier isEqualToString:@"kind"] ? @"元の登録種類" : @"参照状態");
            column.width = [identifier isEqualToString:@"title"] ? 290 : 180;
            [_table addTableColumn:column];
        }
        _table.dataSource = self; _table.delegate = self; _table.rowHeight = 24;
        _table.target = self; _table.doubleAction = @selector(showSelected:);
        _table.allowsMultipleSelection = NO; _table.usesAlternatingRowBackgroundColors = YES;
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.documentView = _table; scroll.hasVerticalScroller = YES; scroll.hasHorizontalScroller = YES;
        _status = [NSTextField wrappingLabelWithString:@"媒体データ未読込"];
        _details = [NSTextField wrappingLabelWithString:@"項目を選択してください"];
        _details.selectable = YES;
        _show = [NSButton buttonWithTitle:@"表示 / 再生準備" target:self action:@selector(showSelected:)];
        _map = [NSButton buttonWithTitle:@"参照ファイルを指定…" target:self action:@selector(mapFile:)];
        _previous = [NSButton buttonWithTitle:@"前" target:self action:@selector(previous:)];
        _next = [NSButton buttonWithTitle:@"次" target:self action:@selector(next:)];
        NSButton *open = [NSButton buttonWithTitle:@"ローカル媒体を追加…" target:self action:@selector(openLocalMedia:)];
        NSStackView *buttons = stack(@[_previous, _next, _show, _map, open], NO);
        NSStackView *layout = stack(@[_status, scroll, _details, buttons], YES);
        fill(layout, self.window.contentView, 16);
        for (NSView *view in @[_status, scroll, _details, buttons]) [view.widthAnchor constraintEqualToAnchor:layout.widthAnchor].active = YES;
        [scroll.heightAnchor constraintGreaterThanOrEqualToConstant:120].active = YES;
        [self refresh];
    }
    return self;
}
- (NSUInteger)entryCount { return _catalog.entries.size(); }
- (NSUInteger)unresolvedCount {
    NSUInteger result = 0;
    for (std::size_t i = 0; i < _catalog.entries.size(); ++i)
        if (!_catalog.entries[i].resolved_path && !_mappings.count(i)) ++result;
    return result;
}
- (NSString *)diagnosticSummary {
    NSMutableArray<NSString *> *messages = [NSMutableArray array];
    for (const auto& message : _catalog.diagnostics) [messages addObject:text(message)];
    for (const auto& entry : _catalog.entries)
        for (const auto& message : entry.diagnostics) [messages addObject:[NSString stringWithFormat:@"%@: %@", text(entry.menu_title), text(message)]];
    return [messages componentsJoinedByString:@"\n"];
}
- (BOOL)previewVisible { return _preview.visible; }
- (BOOL)mediaPlaying { return _playerView.player.rate != 0; }
- (NSString *)previewMessage { return _previewStatus ? _previewStatus.stringValue : @""; }
- (void)loadDataDirectory:(NSURL *)directory {
    ++_generation; [self closePreview]; _mappings.clear(); _catalog = {};
    if (!directory.isFileURL) _catalog.diagnostics.push_back("ローカルのdataフォルダを指定してください");
    else {
        try { _catalog = load_media_catalog(directory.fileSystemRepresentation); }
        catch (const std::exception& error) { _catalog.diagnostics.push_back(error.what()); }
    }
    [_table deselectAll:nil]; [_table reloadData]; [self refresh];
}
- (void)refresh {
    NSMutableArray<NSString *> *messages = [NSMutableArray array];
    for (const auto& message : _catalog.diagnostics) [messages addObject:text(message)];
    _status.stringValue = [NSString stringWithFormat:@"登録 %lu 件 / 参照未解決 %lu 件。割当てと追加はこの実行中のみ保持します。%@",
        static_cast<unsigned long>(self.entryCount), static_cast<unsigned long>(self.unresolvedCount),
        messages.count == 0 ? @"" : [@"\n" stringByAppendingString:[messages componentsJoinedByString:@"\n"]]];
    const NSInteger row = _table.selectedRow;
    const BOOL selected = row >= 0 && static_cast<std::size_t>(row) < _catalog.entries.size();
    _map.enabled = _show.enabled = selected;
    _previous.enabled = selected && row > 0;
    _next.enabled = selected && static_cast<std::size_t>(row + 1) < _catalog.entries.size();
    if (!selected) { _details.stringValue = @"JPEG / PNG画像、macOSが読み込める動画・音声。動画・音声は再生ボタンで開始します。"; return; }
    const auto& entry = _catalog.entries[static_cast<std::size_t>(row)];
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObject:text(entry.display_title)];
    const auto mapped = _mappings.find(static_cast<std::size_t>(row));
    if (mapped != _mappings.end()) [lines addObject:[@"今回の割当て: " stringByAppendingString:text(mapped->second.string())]];
    else if (entry.resolved_path) [lines addObject:text(entry.resolved_path->string())];
    for (const auto& message : entry.diagnostics) [lines addObject:text(message)];
    _details.stringValue = [lines componentsJoinedByString:@"\n"];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)table { (void)table; return self.entryCount; }
- (NSView *)tableView:(NSTableView *)table viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)table;
    const auto index = static_cast<std::size_t>(row);
    if (index >= _catalog.entries.size()) return nil;
    const auto& entry = _catalog.entries[index];
    NSString *value = text(entry.menu_title);
    if ([column.identifier isEqualToString:@"kind"]) value = kindName(entry.kind);
    else if ([column.identifier isEqualToString:@"state"])
        value = _mappings.count(index) ? @"今回の割当て" : (entry.resolved_path ? @"ファイル確認済み" : @"未解決・指定が必要");
    return [NSTextField labelWithString:value];
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification { (void)notification; [self refresh]; }
- (void)selectEntryAtIndex:(NSUInteger)index {
    if (index < self.entryCount) [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    else [_table deselectAll:nil];
    [self refresh];
}
- (void)previous:(id)sender { (void)sender; if (_previous.enabled) [self selectEntryAtIndex:static_cast<NSUInteger>(_table.selectedRow - 1)]; }
- (void)next:(id)sender { (void)sender; if (_next.enabled) [self selectEntryAtIndex:static_cast<NSUInteger>(_table.selectedRow + 1)]; }
- (BOOL)mapSelectedEntryToURL:(NSURL *)url error:(NSError **)error {
    const NSInteger row = _table.selectedRow;
    if (row < 0 || static_cast<std::size_t>(row) >= _catalog.entries.size()) return fail(error, @"登録を選択してください");
    struct stat info{};
    if (!url.isFileURL || stat(url.fileSystemRepresentation, &info) != 0 || !S_ISREG(info.st_mode))
        return fail(error, @"ローカルの通常ファイルを選択してください");
    const std::filesystem::path path(url.fileSystemRepresentation);
    if (media_kind_for_extension(path) == MediaKind::unknown) return fail(error, @"この拡張子の媒体には対応していません");
    [self closePreview]; _mappings[static_cast<std::size_t>(row)] = path;
    [_table reloadData]; [self selectEntryAtIndex:static_cast<NSUInteger>(row)]; return YES;
}
- (void)chooseFileForMapping:(BOOL)mapping {
    const auto generation = _generation;
    NSOpenPanel *panel = [NSOpenPanel openPanel]; panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.message = @"元ファイルや登録を書き換えず、この実行中だけ使用します。";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK || generation != self->_generation) return;
        if (!mapping) {
            MediaEntry entry; entry.menu_title = panel.URL.lastPathComponent.UTF8String;
            entry.display_title = entry.menu_title; entry.kind = media_kind_for_extension(panel.URL.fileSystemRepresentation);
            self->_catalog.entries.push_back(std::move(entry));
            [self->_table reloadData]; [self selectEntryAtIndex:self.entryCount - 1];
        }
        NSError *error = nil;
        if (![self mapSelectedEntryToURL:panel.URL error:&error]) {
            if (!mapping) { self->_catalog.entries.pop_back(); [self->_table reloadData]; [self refresh]; }
            self->_status.stringValue = error.localizedDescription;
        }
    }];
}
- (void)mapFile:(id)sender { (void)sender; if (_map.enabled) [self chooseFileForMapping:YES]; }
- (void)openLocalMedia:(id)sender { (void)sender; [self showWindow:nil]; [self chooseFileForMapping:NO]; }
- (void)buildPreview {
    if (_preview) return;
    _preview = makeWindow(@"媒体プレビュー", NSMakeSize(800, 620)); _preview.delegate = self;
    _preview.minSize = NSMakeSize(560, 420);
    _imageView = [[MediaImageView alloc] initWithFrame:NSMakeRect(0, 0, 760, 450)];
    _playerView = [[AVPlayerView alloc] initWithFrame:_imageView.frame];
    _playerView.controlsStyle = AVPlayerViewControlsStyleInline;
    _zoom = [NSSlider sliderWithValue:1 minValue:0.05 maxValue:4 target:self action:@selector(transformImage:)];
    _rotation = [NSSlider sliderWithValue:0 minValue:-180 maxValue:180 target:self action:@selector(transformImage:)];
    _opacity = [NSSlider sliderWithValue:1 minValue:0 maxValue:1 target:self action:@selector(transformImage:)];
    NSButton *reset = [NSButton buttonWithTitle:@"位置・変形を戻す" target:self action:@selector(resetImage:)];
    NSMutableArray<NSView *> *controlRows = [NSMutableArray array];
    NSArray<NSString *> *controlLabels = @[@"倍率", @"回転", @"不透明度"];
    NSArray<NSSlider *> *sliders = @[_zoom, _rotation, _opacity];
    for (NSUInteger index = 0; index < sliders.count; ++index) {
        NSTextField *label = [NSTextField labelWithString:controlLabels[index]];
        [label.widthAnchor constraintEqualToConstant:68].active = YES;
        [label setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [label setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [sliders[index].widthAnchor constraintGreaterThanOrEqualToConstant:180].active = YES;
        NSStackView *row = stack(@[label, sliders[index]], NO);
        row.alignment = NSLayoutAttributeCenterY;
        [controlRows addObject:row];
    }
    [reset setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [reset setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    _imageControls = stack([controlRows arrayByAddingObject:reset], YES);
    _imageControls.alignment = NSLayoutAttributeLeading;
    _imageControls.spacing = 6;
    for (NSView *row in controlRows) [row.widthAnchor constraintEqualToAnchor:_imageControls.widthAnchor].active = YES;
    _previewStatus = [NSTextField wrappingLabelWithString:@""];
    NSView *canvas = [[NSView alloc] init]; fill(_imageView, canvas, 0); fill(_playerView, canvas, 0);
    NSStackView *layout = stack(@[canvas, _imageControls, _previewStatus], YES);
    fill(layout, _preview.contentView, 12);
    for (NSView *view in @[canvas, _imageControls, _previewStatus]) [view.widthAnchor constraintEqualToAnchor:layout.widthAnchor].active = YES;
    [canvas.heightAnchor constraintGreaterThanOrEqualToConstant:160].active = YES;
}
- (BOOL)previewSelected:(NSError **)error {
    const NSInteger row = _table.selectedRow;
    if (row < 0 || static_cast<std::size_t>(row) >= _catalog.entries.size()) return fail(error, @"登録を選択してください");
    const auto index = static_cast<std::size_t>(row);
    const auto& entry = _catalog.entries[index];
    const auto found = _mappings.find(index);
    const auto path = found == _mappings.end() ? entry.resolved_path : std::optional<std::filesystem::path>(found->second);
    if (!path) return fail(error, @"参照先が未解決です。「参照ファイルを指定」で選択してください");
    const auto kind = media_kind_for_extension(*path);
    if (kind == MediaKind::unknown) return fail(error, @"この拡張子の媒体には対応していません");
    [self closePreview]; [self buildPreview];
    _preview.title = text(entry.menu_title);
    _imageView.hidden = _imageControls.hidden = kind != MediaKind::image;
    _playerView.hidden = kind == MediaKind::image;
    if (kind == MediaKind::image) {
        try {
            const auto image = load_local_image(*path);
            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr pixelsWide:image.width pixelsHigh:image.height
                bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
                bitmapFormat:NSBitmapFormatAlphaNonpremultiplied bytesPerRow:image.width * 4 bitsPerPixel:32];
            if (!bitmap) return fail(error, @"画像の表示領域を確保できません");
            std::memcpy(bitmap.bitmapData, image.rgba.data(), image.rgba.size());
            NSImage *native = [[NSImage alloc] initWithSize:NSMakeSize(image.width, image.height)]; [native addRepresentation:bitmap];
            _imageView.image = native; [self resetImage:nil];
            _previewStatus.stringValue = @"画像をドラッグして移動。長辺1024px以内のプレビューです。元画像は変更しません。";
        } catch (const std::exception& exception) { return fail(error, text(exception.what())); }
    } else {
        struct stat info{};
        if (stat(path->c_str(), &info) != 0 || !S_ISREG(info.st_mode)) return fail(error, @"媒体の通常ファイルを読み込めません");
        NSURL *url = [NSURL fileURLWithFileSystemRepresentation:path->c_str() isDirectory:NO relativeToURL:nil];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetReferenceRestrictionsKey:@(AVAssetReferenceRestrictionForbidAll)}];
        _playerItem = [AVPlayerItem playerItemWithAsset:asset];
        _playerView.player = [AVPlayer playerWithPlayerItem:_playerItem];
        _previewStatus.stringValue = @"読み込み中。準備ができたら再生ボタンで開始してください。";
        [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&itemStatusContext];
    }
    [_preview makeKeyAndOrderFront:nil]; return YES;
}
- (void)showSelected:(id)sender { (void)sender; NSError *error = nil; if (![self previewSelected:&error]) _status.stringValue = error.localizedDescription; }
- (void)transformImage:(id)sender {
    (void)sender; _imageView.zoom = _zoom.doubleValue; _imageView.rotationDegrees = _rotation.doubleValue; _imageView.imageOpacity = _opacity.doubleValue;
}
- (void)resetImage:(id)sender {
    (void)sender; [_imageView resetTransform]; _zoom.doubleValue = _opacity.doubleValue = 1; _rotation.doubleValue = 0;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != &itemStatusContext) { [super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; return; }
    AVPlayerItem *item = object;
    __weak MediaController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        MediaController *controller = weakSelf;
        if (!controller || controller->_playerItem != item) return;
        if (item.status == AVPlayerItemStatusFailed) {
            NSString *message = item.error.localizedDescription;
            controller->_previewStatus.stringValue = [@"再生できません: " stringByAppendingString:message ? message : @"macOS未対応または破損した媒体です"];
        }
        else if (item.status == AVPlayerItemStatusReadyToPlay)
            controller->_previewStatus.stringValue = @"再生ボタンで開始。時間表示・シークはmacOS標準の秒単位です（旧Plusのframe互換ではありません）。";
    });
}
- (void)stopPlayer {
    [_playerView.player pause]; _playerView.player = nil;
    if (_playerItem) { [_playerItem removeObserver:self forKeyPath:@"status" context:&itemStatusContext]; _playerItem = nil; }
}
- (void)closePreview { [self stopPlayer]; [_preview orderOut:nil]; _imageView.image = nil; }
- (void)windowWillClose:(NSNotification *)notification {
    if (notification.object == _preview || notification.object == self.window) [self closePreview];
}
- (void)invalidate { ++_generation; [self closePreview]; [self.window orderOut:nil]; }
- (void)dealloc { [self stopPlayer]; _preview.delegate = nil; }
@end
