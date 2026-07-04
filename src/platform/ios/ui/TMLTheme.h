#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Farb-/Font-Konstanten. Die Panel-Palette ist an einem echten Terraria-
// Settings-Menu-Screenshot (reference/terraria_menu.jpeg) abgelesen -
// eigene Farbwerte, keine kopierten Texturen/Assets.
@interface TMLTheme : NSObject

// -- Trigger-Text (unveraendert seit vorheriger Iteration) --
+ (UIFont *)pixelFontOfSize:(CGFloat)size;
+ (NSAttributedString *)outlinedTitleWithText:(NSString *)text fontSize:(CGFloat)fontSize;

// -- Settings-Panel-Palette (aus reference/terraria_menu.jpeg abgelesen) --
+ (UIColor *)panelBackgroundColor;  // ~#4A5A9A, Panel-Hintergrund
+ (UIColor *)panelBorderColor;      // ~#8FA8E8, heller Panel-Rahmen
+ (UIColor *)titlePillColor;        // ~#6B85D0, Titel-Pille
+ (UIColor *)rowBackgroundColor;    // ~#3B4A7A, Options-Zeilen/Buttons
+ (UIColor *)toggleOnColor;         // ~#4CAF50, gruen = On
+ (UIColor *)toggleOffColor;        // ~#555555, grau = Off
+ (UIColor *)backArrowColor;        // rotes Pfeil-Icon

// ChalkboardSE-Bold ist ein echtes iOS-System-Font (kein Terraria-Asset,
// keine Lizenzfrage), visuell der naechste verfuegbare Treffer zu Terrarias
// eigener Menu-Font.
+ (UIFont *)chalkboardFontOfSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
