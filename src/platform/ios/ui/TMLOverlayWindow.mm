#import "TMLOverlayWindow.h"

@implementation TMLOverlayWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self || hitView == self.rootViewController.view) {
        // Nichts Sichtbares an dieser Stelle getroffen -> Touch an das
        // Fenster darunter (die Host-App) durchreichen.
        return nil;
    }
    return hitView;
}

@end
