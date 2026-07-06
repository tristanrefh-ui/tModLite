#import "TMLBackButton.h"

#import "TMLOutlinedLabel.h"
#import "TMLTheme.h"

@implementation TMLBackButton

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [TMLTheme rowBackgroundColor];
        self.layer.cornerRadius = 10.0;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;

        UIView *arrowView = [[UIView alloc] init];
        arrowView.translatesAutoresizingMaskIntoConstraints = NO;
        arrowView.backgroundColor = [UIColor clearColor];

        CAShapeLayer *arrowLayer = [CAShapeLayer layer];
        arrowLayer.fillColor = [TMLTheme backArrowColor].CGColor;
        UIBezierPath *arrowPath = [UIBezierPath bezierPath];
        [arrowPath moveToPoint:CGPointMake(14, 0)];
        [arrowPath addLineToPoint:CGPointMake(14, 16)];
        [arrowPath addLineToPoint:CGPointMake(0, 8)];
        [arrowPath closePath];
        arrowLayer.path = arrowPath.CGPath;
        arrowLayer.frame = CGRectMake(0, 0, 14, 16);
        [arrowView.layer addSublayer:arrowLayer];

        TMLOutlinedLabel *backLabel = [[TMLOutlinedLabel alloc] init];
        backLabel.text = @"Zurueck";
        backLabel.font = [TMLTheme chalkboardFontOfSize:16.0];

        [self addSubview:arrowView];
        [self addSubview:backLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleTap)];
        [self addGestureRecognizer:tap];

        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToConstant:44.0],
            [self.widthAnchor constraintEqualToConstant:132.0],

            [arrowView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:14.0],
            [arrowView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [arrowView.widthAnchor constraintEqualToConstant:14.0],
            [arrowView.heightAnchor constraintEqualToConstant:16.0],

            [backLabel.leadingAnchor constraintEqualToAnchor:arrowView.trailingAnchor constant:8.0],
            [backLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

- (void)handleTap {
    if (self.onTap) {
        self.onTap();
    }
}

@end
