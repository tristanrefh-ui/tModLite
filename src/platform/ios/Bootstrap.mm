#include <cstdio>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#include "GameContext.hpp"
#include "Runtime.hpp"

namespace {

UIWindow* FindKeyWindow() {
    for (UIScene* scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        UIWindowScene* windowScene = (UIWindowScene*)scene;
        for (UIWindow* window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

void ShowOverlay() {
    if (![UIApplication sharedApplication]) {
        return;
    }

    UIWindow* keyWindow = FindKeyWindow();
    if (!keyWindow) {
        std::printf("[iOS Bootstrap] Kein keyWindow gefunden, Overlay uebersprungen\n");
        return;
    }

    CGFloat topInset = keyWindow.safeAreaInsets.top;
    CGRect frame = CGRectMake(0, topInset, keyWindow.bounds.size.width, 30);

    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.text = @"TModLite v0.1 geladen";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [keyWindow addSubview:label];
    [keyWindow bringSubviewToFront:label];

    std::printf("[iOS Bootstrap] Overlay-Label zum keyWindow hinzugefuegt\n");
}

} // namespace

__attribute__((constructor))
static void tml_ios_bootstrap() {
    static tml::Runtime runtime;

    tml::GameContext& context = runtime.context();
    context.player.name = "PlaceholderPlayer";
    context.world.name = "PlaceholderWorld";

    runtime.start();

    std::printf("[iOS Bootstrap] TModLite geladen und gestartet\n");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        ShowOverlay();
    });
}
