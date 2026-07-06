#import "TMLOverlayManager.h"

#import "TMLInGamePanel.h"
#import "TMLOverlayButton.h"
#import "TMLOverlayViewController.h"
#import "TMLOverlayWindow.h"

#include "../Il2CppBridge.h"

// Welches der beiden Panels (falls ueberhaupt eins) gerade sichtbar ist -
// gebraucht, weil nur das Hauptmenue-Settings-Panel menuMode aendert, das
// In-Game-Panel bewusst nicht.
typedef NS_ENUM(NSInteger, TMLActivePanel) {
    TMLActivePanelNone,
    TMLActivePanelSettings,
    TMLActivePanelInGame,
};

@interface TMLOverlayManager ()

@property (nonatomic, strong, nullable) TMLOverlayWindow *overlayWindow;
@property (nonatomic, strong, nullable) TMLOverlayButton *triggerLabel;
@property (nonatomic, strong, nullable) TMLOverlayPanel *settingsPanel;
@property (nonatomic, strong, nullable) TMLInGamePanel *inGamePanel;
@property (nonatomic, assign) TMLActivePanel activePanel;

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

    TMLOverlayPanel *settingsPanel = [[TMLOverlayPanel alloc] init];
    settingsPanel.alpha = 0.0;
    settingsPanel.hidden = YES;
    settingsPanel.onClose = ^{
        [weakSelf closeActivePanel];
    };
    settingsPanel.onToggleModAtIndex = onToggleModAtIndex;
    [settingsPanel setModRows:modRows];
    [rootView addSubview:settingsPanel];

    TMLInGamePanel *inGamePanel = [[TMLInGamePanel alloc] init];
    inGamePanel.alpha = 0.0;
    inGamePanel.hidden = YES;
    inGamePanel.onClose = ^{
        [weakSelf closeActivePanel];
    };
    [rootView addSubview:inGamePanel];

    // Beide Panels teilen sich dieselbe grosse, zentrierte Positionierung -
    // es ist immer nur eins von beiden gleichzeitig sichtbar.
    UILayoutGuide *safeArea = rootView.safeAreaLayoutGuide;
    for (UIView *panelView in @[settingsPanel, inGamePanel]) {
        [NSLayoutConstraint activateConstraints:@[
            [panelView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
            [panelView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
            [panelView.widthAnchor constraintEqualToAnchor:safeArea.widthAnchor multiplier:0.85],
        ]];
    }

    self.overlayWindow = window;
    self.triggerLabel = trigger;
    self.settingsPanel = settingsPanel;
    self.inGamePanel = inGamePanel;

    NSLog(@"[TMLOverlayManager] Overlay-Trigger installiert (%lu Mods)", (unsigned long)modRows.count);
}

- (void)handleTriggerTap {
    if (self.activePanel != TMLActivePanelNone) {
        NSLog(@"[TMLOverlayManager] Tap erkannt - schliesse aktives Panel");
        [self closeActivePanel];
        return;
    }

    // Kontext bei jedem Oeffnen neu bestimmen: Hauptmenue bekommt das
    // bestehende Settings-Panel (menuMode=10, wie bisher), eine laufende
    // Welt bekommt das neue In-Game-Panel (menuMode bleibt unangetastet,
    // das Spiel laeuft im Hintergrund normal weiter).
    BOOL inMainMenu = TML_IsGameMenuActive();
    NSLog(@"[TMLOverlayManager] Tap erkannt - %@",
          inMainMenu ? @"Hauptmenue erkannt, oeffne Settings-Panel (menuMode=10)"
                     : @"In-Game erkannt, oeffne In-Game-Panel (menuMode unveraendert)");

    if (inMainMenu) {
        TML_SetMenuMode(10);
        [self showPanel:self.settingsPanel asActive:TMLActivePanelSettings];
    } else {
        [self showPanel:self.inGamePanel asActive:TMLActivePanelInGame];
    }
}

- (void)closeActivePanel {
    UIView *panelToHide = nil;
    switch (self.activePanel) {
        case TMLActivePanelSettings:
            TML_SetMenuMode(0);
            panelToHide = self.settingsPanel;
            break;
        case TMLActivePanelInGame:
            panelToHide = self.inGamePanel;
            break;
        case TMLActivePanelNone:
            return;
    }

    self.activePanel = TMLActivePanelNone;
    [self animatePanel:panelToHide show:NO];
}

- (void)showPanel:(UIView *)panelView asActive:(TMLActivePanel)activePanel {
    self.activePanel = activePanel;
    [self animatePanel:panelView show:YES];
}

- (void)animatePanel:(UIView *)panelView show:(BOOL)willShow {
    if (!panelView) {
        return;
    }

    if (willShow) {
        panelView.hidden = NO;
        panelView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    }

    __weak UIView *weakPanel = panelView;
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
