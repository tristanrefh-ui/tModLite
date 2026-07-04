#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Reiner Text-Trigger ("TModLite"), kein Button-Hintergrund, kein Rahmen.
// Der Touch-Bereich ist exakt die Text-Bounding-Box. Wird beim ersten
// Einhaengen in eine Superview per Auto Layout unten rechts an deren
// safeAreaLayoutGuide verankert und bleibt danach fix (kein Drag).
@interface TMLOverlayButton : UIView

@property (nonatomic, copy, nullable) void (^onTap)(void);

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
