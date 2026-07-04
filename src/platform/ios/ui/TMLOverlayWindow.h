#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// UIWindow, das Touches nur auf eigenen sichtbaren Subviews annimmt. Ueberall
// sonst (leere/transparente Flaeche) gibt hitTest nil zurueck, damit UIKit
// den Touch an das naechste Fenster darunter (die Host-App) weiterreicht.
// Ohne das faengt ein vollflaechiges Overlay-Fenster ALLE Touches ab, auch
// dort wo nichts sichtbar ist.
@interface TMLOverlayWindow : UIWindow
@end

NS_ASSUME_NONNULL_END
