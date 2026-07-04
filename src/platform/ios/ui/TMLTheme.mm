#import "TMLTheme.h"

@implementation TMLTheme

+ (UIColor *)woodDarkColor {
    return [UIColor colorWithRed:0.22 green:0.14 blue:0.09 alpha:1.0];
}

+ (UIColor *)woodMidColor {
    return [UIColor colorWithRed:0.42 green:0.29 blue:0.16 alpha:1.0];
}

+ (UIColor *)woodLightColor {
    return [UIColor colorWithRed:0.62 green:0.47 blue:0.28 alpha:1.0];
}

+ (UIColor *)stoneColor {
    return [UIColor colorWithRed:0.34 green:0.33 blue:0.31 alpha:1.0];
}

+ (UIColor *)accentGoldColor {
    return [UIColor colorWithRed:0.85 green:0.67 blue:0.31 alpha:1.0];
}

+ (UIColor *)parchmentColor {
    return [UIColor colorWithRed:0.86 green:0.78 blue:0.63 alpha:1.0];
}

+ (UIColor *)textLightColor {
    return [UIColor colorWithRed:0.94 green:0.89 blue:0.78 alpha:1.0];
}

+ (UIColor *)textMutedColor {
    return [UIColor colorWithRed:0.94 green:0.89 blue:0.78 alpha:0.6];
}

+ (UIFont *)titleFont {
    return [UIFont monospacedSystemFontOfSize:17.0 weight:UIFontWeightBold];
}

+ (UIFont *)bodyFont {
    return [UIFont monospacedSystemFontOfSize:14.0 weight:UIFontWeightMedium];
}

+ (UIFont *)captionFont {
    return [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightRegular];
}

// Bewusst KEINE Kopie/Extraktion von Terrarias tatsaechlicher (lizenzierter)
// Menu-Font. Monospaced + Black-Gewicht ist die kantigste/blockigste
// Kombination, die die System-Fontauswahl hergibt - eine Annaeherung, keine
// Nachbildung.
+ (UIFont *)pixelFontOfSize:(CGFloat)size {
    UIFontDescriptor *descriptor = [[UIFont systemFontOfSize:size weight:UIFontWeightBlack].fontDescriptor
        fontDescriptorWithDesign:UIFontDescriptorSystemDesignMonospaced];
    if (descriptor) {
        return [UIFont fontWithDescriptor:descriptor size:size];
    }
    return [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightBlack];
}

+ (NSAttributedString *)outlinedTitleWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    NSDictionary<NSAttributedStringKey, id> *attributes = @{
        NSFontAttributeName : [self pixelFontOfSize:fontSize],
        NSForegroundColorAttributeName : [UIColor whiteColor],
        NSStrokeColorAttributeName : [UIColor blackColor],
        // Negativer Wert = Fuellung UND Kontur zeichnen (positiv waere nur
        // eine hohle Kontur ohne Fuellung).
        NSStrokeWidthAttributeName : @(-(fontSize * 0.16)),
    };
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

@end
