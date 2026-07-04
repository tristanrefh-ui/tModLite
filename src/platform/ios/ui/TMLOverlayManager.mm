#import "TMLOverlayManager.h"

#import "TMLOverlayButton.h"
#import "TMLOverlayViewController.h"
#import "TMLOverlayWindow.h"

#include "../Il2CppBridge.h"

@interface TMLOverlayManager ()

@property (nonatomic, strong, nullable) TMLOverlayWindow *overlayWindow;
@property (nonatomic, strong, nullable) TMLOverlayButton *triggerLabel;
@property (nonatomic, strong, nullable) TMLOverlayPanel *panel;
@property (nonatomic, assign) BOOL panelVisible;

@end

@implementation TMLOverlayManager

+ (instancetype)sharedManager {
    static TMLOverlayManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMLOverlayManager alloc] init];
    });
    return instance;
}

- (void)presentOverlayWithModRows:(NSArray<TMLOverlayModRow *> *)modRows
                onToggleModAtIndex:(void (^)(NSInteger index, BOOL enabled))onToggleModAtIndex {
    if (self.overlayWindow) {
        return;
    }

    UIWindowScene *windowScene = [self findWindowScene];
    if (!windowScene) {
        NSLog(@"[TMLOverlayManager] Keine UIWindowScene gefunden, Overlay uebersprungen");
        return;
    }

    TMLOverlayWindow *window = [[TMLOverlayWindow alloc] initWithWindowScene:windowScene];
    window.windowLevel = UIWindowLevelAlert + 1.0;
    window.backgroundColor = [UIColor clearColor];
    window.rootViewController = [[TMLOverlayViewController alloc] init];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    window.hidden = NO;

    UIView *rootView = window.rootViewController.view;

    TMLOverlayButton *trigger = [[TMLOverlayButton alloc] init];
    __weak TMLOverlayManager *weakSelf = self;
    trigger.onTap = ^{
        [weakSelf handleTriggerTap];
    };
    [rootView addSubview:trigger];

    TMLOverlayPanel *panel = [[TMLOverlayPanel alloc] init];
    panel.alpha = 0.0;
    panel.hidden = YES;
    panel.onClose = ^{
        // Close-Button schliesst immer (im Gegensatz zum Trigger-Tap, der
        // toggelt) - menuMode geht also immer zurueck auf 0.
        TML_SetMenuMode(0);
        [weakSelf togglePanel];
    };
    panel.onToggleModAtIndex = onToggleModAtIndex;
    [panel setModRows:modRows];
    [rootView addSubview:panel];

    [NSLayoutConstraint activateConstraints:@[
        [panel.trailingAnchor constraintEqualToAnchor:trigger.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:trigger.topAnchor constant:-12.0],
    ]];

    self.overlayWindow = window;
    self.triggerLabel = trigger;
    self.panel = panel;

    NSLog(@"[TMLOverlayManager] Overlay-Trigger installiert (%lu Mods)", (unsigned long)modRows.count);
}

- (void)handleTriggerTap {
    // Vor togglePanel bestimmen, ob wir gerade oeffnen oder schliessen -
    // togglePanel selbst kippt panelVisible.
    BOOL willOpen = !self.panelVisible;
    NSLog(@"[TMLOverlayManager] Tap erkannt - %@", willOpen ? @"oeffne Panel (menuMode=10)"
                                                             : @"schliesse Panel (menuMode=0)");
    TML_SetMenuMode(willOpen ? 10 : 0);
    [self togglePanel];
}

- (void)togglePanel {
    if (!self.panel) {
        return;
    }

    BOOL willShow = !self.panelVisible;
    self.panelVisible = willShow;

    if (willShow) {
        self.panel.hidden = NO;
        self.panel.transform = CGAffineTransformMakeScale(0.85, 0.85);
    }

    __weak TMLOverlayPanel *weakPanel = self.panel;
    [UIView animateWithDuration:0.22
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.4
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        weakPanel.alpha = willShow ? 1.0 : 0.0;
        weakPanel.transform = willShow ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.85, 0.85);
    }
                     completion:^(BOOL finished) {
        if (!willShow) {
            weakPanel.hidden = YES;
        }
    }];
}

- (nullable UIWindowScene *)findWindowScene {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

@end
