#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Zwei gestapelte UILabels: ein dunkler, leicht versetzter Schatten-Layer
// dahinter, ein weisser Text-Layer davor - reproduziert Terrarias
// Text-Look (dunkles Outline/Schlagschatten) als echten Doppel-Layer statt
// per NSAttributedString-Stroke.
@interface TMLOutlinedLabel : UIView

@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, assign) NSTextAlignment textAlignment;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
