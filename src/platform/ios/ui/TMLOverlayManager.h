#pragma once

#import <UIKit/UIKit.h>

#import "TMLOverlayPanel.h"

NS_ASSUME_NONNULL_BEGIN

// Besitzt das Overlay-Fenster und alle UI-Komponenten. Wird vom Bootstrap
// mit Verzoegerung aufgerufen, damit die Host-App-UI schon steht. Kennt
// selbst keine Core-Typen - Bootstrap.mm uebergibt bereits fertige, aus dem
// echten ModLoader-State gebaute Objective-C-Objekte/Blocks.
@interface TMLOverlayManager : NSObject

+ (instancetype)sharedManager;

- (void)presentOverlayWithModRows:(NSArray<TMLOverlayModRow *> *)modRows
                onToggleModAtIndex:(void (^)(NSInteger index, BOOL enabled))onToggleModAtIndex;

@end

NS_ASSUME_NONNULL_END
