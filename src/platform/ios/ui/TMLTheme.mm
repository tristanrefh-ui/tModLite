#import "TMLTheme.h"

@implementation TMLTheme

// Bewusst KEINE Kopie/Extraktion von Terrarias tatsaechlicher (lizenzierter)
// Menu-Font. Monospaced + Black-Gewicht ist die kantigste/blockigste
// Kombination, die die System-Fontauswahl hergibt - eine Annaeherung, keine
// Nachbildung. Wird nur noch vom Trigger-Text genutzt (siehe
// chalkboardFontOfSize fuer das neue Settings-Panel).
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

+ (UIColor *)panelBackgroundColor {
    return [UIColor colorWithRed:0.290 green:0.353 blue:0.604 alpha:1.0];
}

+ (UIColor *)panelBorderColor {
    return [UIColor colorWithRed:0.561 green:0.659 blue:0.910 alpha:1.0];
}

+ (UIColor *)titlePillColor {
    return [UIColor colorWithRed:0.420 green:0.522 blue:0.816 alpha:1.0];
}

+ (UIColor *)rowBackgroundColor {
    return [UIColor colorWithRed:0.231 green:0.290 blue:0.478 alpha:1.0];
}

+ (UIColor *)toggleOnColor {
    return [UIColor colorWithRed:0.298 green:0.686 blue:0.314 alpha:1.0];
}

+ (UIColor *)toggleOffColor {
    return [UIColor colorWithWhite:0.333 alpha:1.0];
}

+ (UIColor *)backArrowColor {
    return [UIColor colorWithRed:0.827 green:0.184 blue:0.184 alpha:1.0];
}

+ (UIFont *)chalkboardFontOfSize:(CGFloat)size {
    UIFont *font = [UIFont fontWithName:@"ChalkboardSE-Bold" size:size];
    return font ?: [UIFont boldSystemFontOfSize:size];
}

@end
