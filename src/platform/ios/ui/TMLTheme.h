#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Eigenes, an Terraria angelehntes Holz-/Stein-Farbschema. Keine Terraria-
// Assets, nur die Farbstimmung (gedaempftes Braun/Beige, dunkle Rahmen).
@interface TMLTheme : NSObject

+ (UIColor *)woodDarkColor;
+ (UIColor *)woodMidColor;
+ (UIColor *)woodLightColor;
+ (UIColor *)stoneColor;
+ (UIColor *)accentGoldColor;
+ (UIColor *)parchmentColor;
+ (UIColor *)textLightColor;
+ (UIColor *)textMutedColor;

+ (UIFont *)titleFont;
+ (UIFont *)bodyFont;
+ (UIFont *)captionFont;

// Kantige, blockige System-Font (kein echtes Pixel-Font-Asset) fuer den
// Terraria-anmutenden Retro-Look von Marken-Text (Trigger, Panel-Titel).
+ (UIFont *)pixelFontOfSize:(CGFloat)size;

// Weisser Text mit duennem dunklem Outline, wie Terrarias eigene UI-Texte.
+ (NSAttributedString *)outlinedTitleWithText:(NSString *)text fontSize:(CGFloat)fontSize;

@end

NS_ASSUME_NONNULL_END
