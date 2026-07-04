#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Erzwingt Landscape unabhaengig von der Geraete-Ausrichtung. Terraria laeuft
// ausschliesslich im Querformat; ohne diesen Lock kann das separate
// Overlay-Fenster bei Rotation trotzdem eine eigene Ausrichtung anfordern.
@interface TMLOverlayViewController : UIViewController
@end

NS_ASSUME_NONNULL_END
