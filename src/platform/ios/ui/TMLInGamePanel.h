#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Panel fuer den in-game-Zustand (Terraria.Main.gameMenu == false): im
// Gegensatz zum Hauptmenue-Settings-Panel (TMLOverlayPanel) aendert dieses
// Panel NICHT menuMode - das Spiel laeuft im Hintergrund normal weiter,
// kein Screen-Wechsel. Aktuell ein Platzhalter (Titel + Zurueck) - die
// fruehere Hook-Test-Diagnose wurde nach experimental/ verschoben (siehe
// docs/technical-limitations.md). Echte In-Game-Features kommen hier
// perspektivisch dazu (siehe docs/roadmap.md).
@interface TMLInGamePanel : UIView

@property (nonatomic, copy, nullable) void (^onClose)(void);

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
