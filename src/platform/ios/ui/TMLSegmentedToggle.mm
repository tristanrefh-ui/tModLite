#import "TMLSegmentedToggle.h"

#import "TMLOutlinedLabel.h"
#import "TMLTheme.h"

@interface TMLSegmentedToggle ()

@property (nonatomic, strong) UIView *offSegment;
@property (nonatomic, strong) UIView *onSegment;

@end

@implementation TMLSegmentedToggle

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _on = NO;

        _offSegment = [self makeSegmentWithText:@"Off"];
        _onSegment = [self makeSegmentWithText:@"On"];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ _offSegment, _onSegment ]];
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.spacing = 4.0;
        stack.distribution = UIStackViewDistributionFillEqually;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [self.widthAnchor constraintEqualToConstant:104.0],
            [self.heightAnchor constraintEqualToConstant:30.0],
        ]];

        UITapGestureRecognizer *offTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleOffTap)];
        [_offSegment addGestureRecognizer:offTap];

        UITapGestureRecognizer *onTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleOnTap)];
        [_onSegment addGestureRecognizer:onTap];

        [self updateAppearance];
    }
    return self;
}

- (UIView *)makeSegmentWithText:(NSString *)text {
    UIView *segment = [[UIView alloc] init];
    segment.translatesAutoresizingMaskIntoConstraints = NO;
    segment.layer.cornerRadius = 15.0;
    segment.clipsToBounds = YES;
    segment.userInteractionEnabled = YES;

    TMLOutlinedLabel *label = [[TMLOutlinedLabel alloc] init];
    label.text = text;
    label.font = [TMLTheme chalkboardFontOfSize:13.0];
    label.textAlignment = NSTextAlignmentCenter;
    [segment addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:segment.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:segment.centerYAnchor],
    ]];

    return segment;
}

- (void)handleOffTap {
    if (!self.isOn) {
        return; // bereits Off - kein Wechsel, kein onChange (sonst wuerde
                // ein blindes toggleMod(name) auf Aufruferseite faelschlich
                // umkippen)
    }
    [self setOn:NO animated:YES];
    if (self.onChange) {
        self.onChange(NO);
    }
}

- (void)handleOnTap {
    if (self.isOn) {
        return; // bereits On - kein Wechsel, kein onChange
    }
    [self setOn:YES animated:YES];
    if (self.onChange) {
        self.onChange(YES);
    }
}

- (void)setOn:(BOOL)on {
    _on = on;
    [self updateAppearance];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    if (_on == on) {
        return;
    }
    _on = on;
    if (animated) {
        [UIView animateWithDuration:0.15
                          animations:^{
            [self updateAppearance];
        }];
    } else {
        [self updateAppearance];
    }
}

- (void)updateAppearance {
    self.onSegment.backgroundColor = [[TMLTheme toggleOnColor] colorWithAlphaComponent:self.isOn ? 1.0 : 0.35];
    self.offSegment.backgroundColor = [[TMLTheme toggleOffColor] colorWithAlphaComponent:self.isOn ? 0.35 : 1.0];
}

@end
