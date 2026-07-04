#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Eine Options-Zeile im Settings-Panel: eigene abgerundete Box, Label
// links, Off/On-Segment-Toggle rechts - Stil an Terrarias "Autoswing"/
// "Movement Stick Aim"-Zeilen angelehnt.
@interface TMLSettingsRow : UIView

@property (nonatomic, copy, nullable) void (^onToggle)(BOOL isOn);

- (instancetype)initWithTitle:(NSString *)title enabled:(BOOL)enabled NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)setToggleOn:(BOOL)on animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
