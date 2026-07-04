#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Zweigeteilter Off/On-Schalter im Terraria-Stil: zwei eigene Pillen
// nebeneinander (kein iOS-Wisch-Kapsel-Switch), gruen fuer On, grau fuer
// Off, der jeweils inaktive Zustand gedimmt.
@interface TMLSegmentedToggle : UIView

@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, copy, nullable) void (^onChange)(BOOL isOn);

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
