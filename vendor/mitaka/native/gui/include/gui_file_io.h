#pragma once
#import <Foundation/Foundation.h>

// 読み込み中にファイルが増えても、最大1MiB+検査用1バイトしか取得しない。
NSData *boundedSessionData(NSURL *url, NSError **error);

// 明示した原本と、保存先の祖先から認識できる旧アプリ・天文データを保護する。
BOOL canWriteUserOutput(NSURL *url, NSArray<NSURL *> *protectedRoots);
