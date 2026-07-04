#import "TMLOverlayPanel.h"

#import "TMLOutlinedLabel.h"
#import "TMLSettingsRow.h"
#import "TMLTheme.h"

@implementation TMLOverlayModRow

+ (instancetype)rowWithName:(NSString *)name version:(NSString *)version enabled:(BOOL)enabled {
    TMLOverlayModRow *row = [[TMLOverlayModRow alloc] init];
    row->_name = [name copy];
    row->_version = [version copy];
    row->_enabled = enabled;
    return row;
}

@end

@interface TMLOverlayPanel ()

@property (nonatomic, strong) UIStackView *rowStack;

@end

@implementation TMLOverlayPanel

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self configureAppearance];
        [self configureContent];
        [self setModRows:@[]];
    }
    return self;
}

- (void)configureAppearance {
    self.backgroundColor = [TMLTheme panelBackgroundColor];
    self.layer.cornerRadius = 14.0;
    self.layer.borderWidth = 3.5;
    self.layer.borderColor = [TMLTheme panelBorderColor].CGColor;
    self.clipsToBounds = YES;
}

- (void)configureContent {
    UIView *titlePill = [[UIView alloc] init];
    titlePill.translatesAutoresizingMaskIntoConstraints = NO;
    titlePill.backgroundColor = [TMLTheme titlePillColor];
    [self addSubview:titlePill];

    TMLOutlinedLabel *titleLabel = [[TMLOutlinedLabel alloc] init];
    titleLabel.text = @"TModLite";
    titleLabel.font = [TMLTheme chalkboardFontOfSize:20.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titlePill addSubview:titleLabel];

    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisVertical;
    rowStack.spacing = 10.0;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.rowStack = rowStack;
    [self addSubview:rowStack];

    UIView *backButton = [self buildBackButton];
    [self addSubview:backButton];

    [NSLayoutConstraint activateConstraints:@[
        [titlePill.topAnchor constraintEqualToAnchor:self.topAnchor constant:16.0],
        [titlePill.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [titlePill.heightAnchor constraintEqualToConstant:36.0],

        [titleLabel.leadingAnchor constraintEqualToAnchor:titlePill.leadingAnchor constant:24.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:titlePill.trailingAnchor constant:-24.0],
        [titleLabel.centerYAnchor constraintEqualToAnchor:titlePill.centerYAnchor],

        [rowStack.topAnchor constraintEqualToAnchor:titlePill.bottomAnchor constant:20.0],
        [rowStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [rowStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],

        [backButton.topAnchor constraintEqualToAnchor:rowStack.bottomAnchor constant:20.0],
        [backButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [backButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
    ]];
}

- (UIView *)buildBackButton {
    UIView *backButton = [[UIView alloc] init];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    backButton.backgroundColor = [TMLTheme rowBackgroundColor];
    backButton.layer.cornerRadius = 10.0;
    backButton.clipsToBounds = YES;
    backButton.userInteractionEnabled = YES;

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

    [backButton addSubview:arrowView];
    [backButton addSubview:backLabel];

    UITapGestureRecognizer *backTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handleBackTap)];
    [backButton addGestureRecognizer:backTap];

    [NSLayoutConstraint activateConstraints:@[
        [backButton.heightAnchor constraintEqualToConstant:44.0],
        [backButton.widthAnchor constraintEqualToConstant:132.0],

        [arrowView.leadingAnchor constraintEqualToAnchor:backButton.leadingAnchor constant:14.0],
        [arrowView.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [arrowView.widthAnchor constraintEqualToConstant:14.0],
        [arrowView.heightAnchor constraintEqualToConstant:16.0],

        [backLabel.leadingAnchor constraintEqualToAnchor:arrowView.trailingAnchor constant:8.0],
        [backLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
    ]];

    return backButton;
}

- (void)handleBackTap {
    if (self.onClose) {
        self.onClose();
    }
}

- (void)setModRows:(NSArray<TMLOverlayModRow *> *)modRows {
    for (UIView *rowView in self.rowStack.arrangedSubviews.copy) {
        [self.rowStack removeArrangedSubview:rowView];
        [rowView removeFromSuperview];
    }

    if (modRows.count == 0) {
        TMLOutlinedLabel *emptyLabel = [[TMLOutlinedLabel alloc] init];
        emptyLabel.text = @"Keine Mods geladen";
        emptyLabel.font = [TMLTheme chalkboardFontOfSize:15.0];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        [self.rowStack addArrangedSubview:emptyLabel];
        return;
    }

    [modRows enumerateObjectsUsingBlock:^(TMLOverlayModRow *row, NSUInteger index, BOOL *stop) {
        TMLSettingsRow *rowView = [[TMLSettingsRow alloc] initWithTitle:row.name enabled:row.enabled];
        __weak TMLOverlayPanel *weakSelf = self;
        rowView.onToggle = ^(BOOL isOn) {
            if (weakSelf.onToggleModAtIndex) {
                weakSelf.onToggleModAtIndex((NSInteger)index, isOn);
            }
        };
        [self.rowStack addArrangedSubview:rowView];
    }];
}

@end
