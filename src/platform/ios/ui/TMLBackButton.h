#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Wiederverwendbarer "Zurueck"-Button im Terraria-Panel-Stil (rotes
// Pfeil-Icon + Chalkboard-Label) - von TMLOverlayPanel und TMLInGamePanel
// genutzt, damit beide Panels optisch identisch schliessen.
@interface TMLBackButton : UIView

@property (nonatomic, copy, nullable) void (^onTap)(void);

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
